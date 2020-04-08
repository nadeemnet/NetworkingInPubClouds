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

resource "aws_s3_bucket" "b" {
  bucket = "nadeem.networkinginpubclouds"
  acl    = "private"
}

resource "aws_s3_bucket_object" "files" {
  for_each      = fileset("./files/", "**/*.*")
  bucket        = aws_s3_bucket.b.id
  key           = "files/${each.value}"
  source        = "files/${each.value}"
  acl           = "private"
}

resource "aws_s3_bucket_object" "images" {
  for_each      = fileset("./images/", "**/*.*")
  bucket        = aws_s3_bucket.b.id
  key           = "images/${each.value}"
  source        = "images/${each.value}"
  acl           = "public-read"
}

resource "aws_instance" "web" {
    ami = "ami-07ebfd5b3428b6f4d"
    instance_type = "t2.micro"
    key_name = "NetworkingInPubClouds"
    vpc_security_group_ids = [aws_security_group.sg-all-ssh-in.id, aws_security_group.sg-all-http-in.id, aws_security_group.sg-all-out.id]
    tags = {
      Name = "web-server"
    }
}

output "public_ip" {
    value = aws_instance.web.public_ip
}

resource "local_file" "public_ip" {
  content  = aws_instance.web.public_ip
  filename = "public_ip.txt"
}



data "aws_route53_zone" "selected" {
  name         = "example.net."
}

resource "aws_route53_record" "web1" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "web1.example.net"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.web.public_ip]
}
