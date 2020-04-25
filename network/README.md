# Create Virtual Networking Infrastructure

As a part of this project, I am building following components.

1. Create an AWS VPC and add one public subnet and one private subnet
2. Create a route table for public subnet and add an Internet Gateway to it.
3. Create a route table for private subnet and add a NAT Gateway to it.
4. Create different security groups, detail will be later in the document.
5. Deploy a jumphost in public subnet and ssh access is allowed from admin host only.
6. Deploy a web server in public subnet and allow tcp/80 from anywhere.
7. Deploy a backend server (aka private server) that can only talk to web server.
8. jumphost is allowed to talk (tcp/22) to both web server and backend server.

## Create VPC, public and private subnets
Following terraform code deploys a VPC, one public subnet and one private subnet. 
The ec2 instances deployed in public subnet will receive a public IP whereas no public IP are assigned in private subnet.

```
resource "aws_vpc" "nl-vpc" {
  cidr_block           = var.vpc_cidrblock
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = "nl-vpc"
  }
}

resource "aws_subnet" "s1" {
  vpc_id                  = aws_vpc.nl-vpc.id
  cidr_block              = var.subnets.s1.cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az
  tags = {
    Name = var.subnets.s1.name
  }
}

resource "aws_subnet" "s2" {
  vpc_id                  = aws_vpc.nl-vpc.id
  cidr_block              = var.subnets.s2.cidr
  map_public_ip_on_launch = false
  availability_zone       = var.az
  tags = {
    Name = var.subnets.s2.name
  }
}
```

## Create an Internet Gateway and a Route Table for Public Subnet
Note that a default route is point to the Internet Gateway.

```
# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.nl-vpc.id
  tags = {
    Name = "nl-igw"
  }
}

# Create route table for public subnet
# Note that internet gateway is added as a defaul route
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.nl-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt_public"
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "s1" {
  depends_on     = [aws_subnet.s1]
  subnet_id      = aws_subnet.s1.id
  route_table_id = aws_route_table.rt_public.id
}
```

## Create a NAT Gateway and Route Table for Private Subnet
NAT Gateway is used in case private server needs to download patches from Internet.
Note that NAT Gateway is deployed in Public Subnet and an Elastic IP address is assigned to it.
The default route in the routing table points to NAT Gateway.

```
# Create route table for private subnet
# Note that default route points to NAT Gateway
resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.nl-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }  
  tags = {
    Name = "rt_private"
  }
}
# Associate route table with private subnet
resource "aws_route_table_association" "s2" {
  depends_on     = [aws_subnet.s2]
  subnet_id      = aws_subnet.s2.id
  route_table_id = aws_route_table.rt_private.id
}

# Allocate Elastic IP for NAT GW
resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "nl-ngw"
  }  
}

# Create NAT gateway in public subnet
resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.s1.id
  allocation_id = aws_eip.nat.id
  tags = {
    Name = "nl-ngw"
  }  
}
```

## Access Control with Security Groups.
Although Network ACL can be used to limit the traffic flow, but here I am only using Security Groups. Security Groups are stateful and easier to manage.

The following security group allows tcp/80 traffic from anywhere. This is applied to the webserver.

```
resource "aws_security_group" "sg-all-http-in" {
  name        = "all-http-in"
  description = "all-http-in"
  vpc_id      = aws_vpc.nl-vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

The following two security groups enable the communication between webserver and backend server.
The first security group is applied to web server and second security group is applied to backend server.
Note that in the second security group, first security group is used as a source. 
This means that no matter what the IP address of the web server is, as long as it is tagged with security group sg-web, it is allowed to talk to backend server. 

```
resource "aws_security_group" "sg-web" {
  name        = "web"
  description = "web"
  vpc_id      = aws_vpc.nl-vpc.id
}

resource "aws_security_group" "sg-web-in" {
  name        = "web-in"
  description = "web-in"
  vpc_id      = aws_vpc.nl-vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    security_groups = [aws_security_group.sg-web.id]
  }
}
```

The following two security groups enable communication between jumphost and other servers.
The first security group is applied to jumphost and second security groups is applied to webserver and backend server. 

```
resource "aws_security_group" "sg-jumphost" {
  name        = "jumphost"
  description = "jumphost"
  vpc_id      = aws_vpc.nl-vpc.id
}

resource "aws_security_group" "sg-jumphost-in" {
  name        = "jumphost-in"
  description = "jumphost-in"
  vpc_id      = aws_vpc.nl-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.sg-jumphost.id]
  }
}
```

The following security groups are used to restrict ssh access to jumphost. Note that only administrator's host is allowed for ssh.

```
data "external" "ip" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
}

output "my_public_ip" {
  value = data.external.ip.result.ip
}

resource "aws_security_group" "sg-my-public-ip-in" {
  name        = "my-public-ip-in"
  description = "my-public-ip-in"
  vpc_id      = aws_vpc.nl-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.ip.result.ip}/32"]
  }
}
```


## Server deployment 
This portion is similar to the last project. All the required security groups are added to allow/deny traffic flows. Once the server's are deployed with Terraform code, Ansible is used for other configuration on the servers. Aministrator ssh config file is customized as follows to access public and private servers.

```
@ubuntu:~/.ssh$ cat config
host jumphost
  user ubuntu
  hostname 1.2.3.4
  IdentitiesOnly yes
  IdentityFile ~/NetworkingInPubClouds.pem

host public_server 10.0.1.100
  user ubuntu
  hostname 10.0.1.100
  IdentitiesOnly yes
  IdentityFile ~/NetworkingInPubClouds.pem
  ProxyCommand ssh -q -W %h:%p jumphost

host private_server 10.0.2.100
  user ubuntu
  hostname 10.0.2.100
  IdentitiesOnly yes
  IdentityFile ~/NetworkingInPubClouds.pem
  ProxyCommand ssh -q -W %h:%p jumphost
```

## Verification

1. Verified that jumphost can be accessed through SSH from admin host only.
2. Verified that web server can be accessed from anywhere.
3. Verified that jumphost can access both public and private server through SSH.
4. Verified that web server can access Internet (for security patches etc.)
5. Verified that private server can access Internet through NAT GW (for security patches etc.)

If needed, outbound Internet access can be disabled by removing a security group.


