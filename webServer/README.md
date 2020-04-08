# Deploy a Cloud-Based Web Server

As a part of this project, on a high level I am doing following tasks:

1. An Ubuntu VM is deployed in AWS cloud using Terraform.
2. AWS Security Groups are created using Terraform.
3. These Security Groups limit incoming traffic to http and ssh
4. All outbound traffic is allowed
5. "images" and "files" directories are uploaded to S3 buckets using Terraform
6. images directory contains all the images used in the website
7. files directory backs up all apache related config files.
8. A record is created in AWS Route53 for the website.
9. After VM is ready, Ansible is used to install and configure Apache webserver.

## VM Deployment

Following Terraform code deploys VM, and adds security groups.

```
resource "aws_instance" "web" {
    ami = "ami-07ebfd5b3428b6f4d"
    instance_type = "t2.micro"
    key_name = "NetworkingInPubClouds"
    vpc_security_group_ids = [aws_security_group.sg-all-ssh-in.id, aws_security_group.sg-all-http-in.id, aws_security_group.sg-all-out.id]
    tags = {
      Name = "web-server"
    }
}
```

## Adding A records in Route53 DNS

VM's public IP is retrieved and an A record is created.

```
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
```

## Backing up files to S3 bucket

Following code backs up "images" and "files" directories to S3 buckets.
The files in images directory are saved in public-read access level. Web pages are configured in such a way that images are directly downloaded from S3 bucket to user's station.
The files in the files directory are saved with private access level. (not visible to public). These files contain apache configs.
I initially wrote Ansible Playbook to upload folders to S3 buckets. (super easy). But then I reverted to Terraform so it can be destroyed when I run "terraform destroy"

```
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
```

## Installing and Configuring Apache web server.

This is done through following Ansible Playbook. Most of the content in this playbook was borrowed from Digital Ocean's community playbooks.

```
- hosts: all
  become: true
  vars_files:
    - vars/default.yml

  tasks:
    - name: Install prerequisites
      apt: name={{ item }} update_cache=yes state=latest force_apt_get=yes
      loop: [ 'aptitude' ]

    - name: Install Apache
      apt: name=apache2 update_cache=yes state=latest

    - name: Create document root
      file:
        path: "/var/www/{{ http_host }}"
        state: directory
        owner: "{{ app_user }}"
        mode: '0755'

    - name: Copy index test page
      template:
        src: "files/index.html.j2"
        dest: "/var/www/{{ http_host }}/index.html"

    - name: Set up Apache virtualhost
      template:
        src: "files/apache.conf.j2"
        dest: "/etc/apache2/sites-available/{{ http_conf }}"

    - name: Enable new site
      shell: /usr/sbin/a2ensite {{ http_conf }}
      notify: Reload Apache

    - name: Disable default Apache site
      shell: /usr/sbin/a2dissite 000-default.conf
      when: disable_default
      notify: Reload Apache

    - name: "UFW - Allow HTTP on port {{ http_port }}"
      ufw:
        rule: allow
        port: "{{ http_port }}"
        proto: tcp

  handlers:
    - name: Reload Apache
      service:
        name: apache2
        state: reloaded

    - name: Restart Apache
      service:
        name: apache2
        state: restarted
```

## How to run Ansible Playbook

**ansible-playbook -i inventory_aws_ec2.yaml playbook.yml -u ubuntu**

The above command makes use of dynmaic inventory. Ansible.cfg file enables aws_ec2 plugin. I have also copied public IP of the websever into a file public_ip.txt in case soemone is interested in creating an inventory file.
Ansible Playbook is run from python virtual enviroment having following packages

```
ansible==2.9.6
boto3==1.12.34
botocore==1.15.34
cffi==1.14.0
cryptography==2.8
docutils==0.15.2
Jinja2==2.11.1
jmespath==0.9.5
MarkupSafe==1.1.1
pkg-resources==0.0.0
pycparser==2.20
python-dateutil==2.8.1
PyYAML==5.3.1
s3transfer==0.3.3
six==1.14.0
urllib3==1.25.8

```