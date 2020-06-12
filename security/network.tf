provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}


variable "region" {
  type    = string
  default = "us-east-1"
}

variable access_key {}
variable secret_key {}

## create the VPC
resource "aws_vpc" "nl-vpc" {
  cidr_block                       = var.vpc_cidrblock
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  tags = {
    Name = "nl-vpc"
  }
}

## create public subnet
resource "aws_subnet" "s1" {
  vpc_id                          = aws_vpc.nl-vpc.id
  cidr_block                      = var.subnets.s1.cidr
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.nl-vpc.ipv6_cidr_block, 8, 1)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = var.az
  tags = {
    Name = var.subnets.s1.name
  }
}

## create private subnet
## Note that no public IP address is assinged here.
resource "aws_subnet" "s2" {
  vpc_id                          = aws_vpc.nl-vpc.id
  cidr_block                      = var.subnets.s2.cidr
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.nl-vpc.ipv6_cidr_block, 8, 2)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true
  availability_zone               = var.az
  tags = {
    Name = var.subnets.s2.name
  }
}

## create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.nl-vpc.id
  tags = {
    Name = "nl-igw"
  }
}

## create the route table for public subnet
## Note that internet gateway is added as a defaul route
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.nl-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt_public"
  }
}

## create the route table for private subnet
resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.nl-vpc.id
  tags = {
    Name = "rt_private"
  }
}

# associating route table with public subnet
resource "aws_route_table_association" "s1" {
  depends_on     = [aws_subnet.s1]
  subnet_id      = aws_subnet.s1.id
  route_table_id = aws_route_table.rt_public.id
}

# associating route table with private subnet
resource "aws_route_table_association" "s2" {
  depends_on     = [aws_subnet.s2]
  subnet_id      = aws_subnet.s2.id
  route_table_id = aws_route_table.rt_private.id
}
