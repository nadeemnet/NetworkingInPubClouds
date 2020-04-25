variable "region" {
  default = "us-east-1"
}

variable "vpc_cidrblock" {
  default = "10.0.0.0/16"
}

variable "az" {
  default = "us-east-1a"
}
variable "enable_dns_support" {
  default = "true"
}

variable "enable_dns_hostnames" {
  default = "true"
}

variable "subnets" {
  default = {
    "s1" = {
      "name" = "public-subnet"
      "cidr" = "10.0.1.0/24"
    },
    "s2" = {
      "name" = "private-subnet"
      "cidr" = "10.0.2.0/24"
    }
  }
}
