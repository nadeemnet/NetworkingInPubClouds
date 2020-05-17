# Create Virtual Networking Infrastructure

This project builds on top of the previous one. IPv6 is implemented here, and all hosts are dual stacked. I will focus on IPv6 part as IPv4 part is not changed. On a high level, following tasks are added.

1. Enable IPv6 in VPC
2. Enabel IPv6 in Public and Private Subnet
3. In the Public Subnet Route Table, create a defualt route for IPv6.
4. Add IPv6 cidr blocks in the security groups.
5. Deploy a dual stacked jumphost in public subnet and ssh access is allowed from admin host only.
6. Deploy a dual stacked web server in public subnet and allow tcp/80 from anywhere.
7. Deploy a dual backend server (aka private server) that can only talk to web server.
8. jumphost is allowed to talk (tcp/22) to both web server and backend server.

## Enable IPv6 in VPC
I only had to add following line to enable IPv6 in existing VPC.

```
 assign_generated_ipv6_cidr_block = true
```

## Add IPv6 to Public and Private Subnets
Following two lines did the job.  It was nice to learn about Terraform cidrsubnet function.

```
ipv6_cidr_block                 = cidrsubnet(aws_vpc.nl-vpc.ipv6_cidr_block, 8, 1)
ipv6_cidr_block                 = cidrsubnet(aws_vpc.nl-vpc.ipv6_cidr_block, 8, 2)
```

## Add IPv6 default route in Public Subnet
Following lines were added to the existing terraform resource.
```
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
```


## Add IPv6 to the public web server'security group.
Adding following line to the existing security group of web server allows access from any IPv6 address.

```
  ipv6_cidr_blocks = ["::/0"]
```


## Verification

I could have written Ansible Playbook for verification, but I decided to give Pytest a try. I have not used Pytest before, but it turns out that it is very easy to use.

**test_connectivity.py** This file verifies that jumphost is accessible on tcp/22. This also verifies that public sever is NOT accessible on tcp/22

**test_connectivityv6** This file should be run on jumphost, and it verifies that jumphost can reach public and private server using IPv6.

