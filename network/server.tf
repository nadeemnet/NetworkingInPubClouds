resource "aws_s3_bucket" "b" {
  bucket = "nadeem.networkinginpubclouds"
  acl    = "private"
}

resource "aws_s3_bucket_object" "files" {
  for_each = fileset("./files/", "**/*.*")
  bucket   = aws_s3_bucket.b.id
  key      = "files/${each.value}"
  source   = "files/${each.value}"
  acl      = "private"
}

resource "aws_s3_bucket_object" "images" {
  for_each = fileset("./images/", "**/*.*")
  bucket   = aws_s3_bucket.b.id
  key      = "images/${each.value}"
  source   = "images/${each.value}"
  acl      = "public-read"
}

data "aws_route53_zone" "selected" {
  name = "lughmani.net."
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.lughmani.net"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.pub-svr.public_ip]
}
resource "aws_network_interface" "pub-svr" {
  subnet_id       = aws_subnet.s1.id
  private_ips     = ["10.0.1.100"]
  security_groups = [aws_security_group.sg-web.id, aws_security_group.sg-all-http-in.id, aws_security_group.sg-all-out.id, aws_security_group.sg-jumphost-in.id]
  depends_on      = [aws_subnet.s1]
  tags = {
    Name = "pub-svr-eth0"
  }
}

resource "aws_instance" "pub-svr" {
  ami           = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.micro"
  key_name      = "NetworkingInPubClouds"
  network_interface {
    network_interface_id = aws_network_interface.pub-svr.id
    device_index         = 0
  }
  tags = {
    Name = "pub-svr"
  }
}

resource "aws_network_interface" "private-svr" {
  subnet_id       = aws_subnet.s2.id
  private_ips     = ["10.0.2.100"]
  security_groups = [aws_security_group.sg-web-in.id, aws_security_group.sg-all-out.id, aws_security_group.sg-jumphost-in.id]
  depends_on      = [aws_subnet.s2]
  tags = {
    Name = "private-svr-eth0"
  }
}

resource "aws_instance" "private-svr" {
  ami           = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.micro"
  key_name      = "NetworkingInPubClouds"
  network_interface {
    network_interface_id = aws_network_interface.private-svr.id
    device_index         = 0
  }
  tags = {
    Name = "private-svr"
  }
}

resource "aws_network_interface" "jumphost" {
  subnet_id       = aws_subnet.s1.id
  private_ips     = ["10.0.1.101"]
  security_groups = [aws_security_group.sg-my-public-ip-in.id, aws_security_group.sg-all-out.id, aws_security_group.sg-jumphost.id ]
  depends_on      = [aws_subnet.s1]
  tags = {
    Name = "jumphost-eth0"
  }
}

resource "aws_instance" "jumphost" {
  ami           = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.micro"
  key_name      = "NetworkingInPubClouds"
  network_interface {
    network_interface_id = aws_network_interface.jumphost.id
    device_index         = 0
  }
  tags = {
    Name = "jumphost"
  }
}