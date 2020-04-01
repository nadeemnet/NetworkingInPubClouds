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

resource "aws_security_group" "sg-all-icmp-in" {
  name        = "all-icmp-in"
  description = "all-icmp-in"
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "all-icmp-in"
  }
}
