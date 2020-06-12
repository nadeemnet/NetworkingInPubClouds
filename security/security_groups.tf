
resource "aws_security_group" "sg-all-http-in" {
  name        = "all-http-in"
  description = "all-http-in"
  vpc_id      = aws_vpc.nl-vpc.id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_security_group" "sg-all-out" {
  name        = "all-out"
  description = "all outbound traffic"
  vpc_id      = aws_vpc.nl-vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

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
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-jumphost.id]
  }
}

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
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [aws_security_group.sg-web.id]
  }
}