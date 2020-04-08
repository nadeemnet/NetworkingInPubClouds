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

resource "aws_security_group" "sg-all-ssh-in" {
  name        = "all-ssh-in"
  description = "all-ssh-in"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "all-ssh-in"
  }  
}

resource "aws_security_group" "sg-all-http-in" {
  name        = "all-http-in"
  description = "all-http-in"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "all-http-in"
  }  
}

resource "aws_security_group" "sg-all-out" {
  name        = "all-out"
  description = "all outbound traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
