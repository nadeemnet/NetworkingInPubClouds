# Secure Your Public Cloud Deployment

This project builds on top of the previous one. Here is a list of security measures carried from the previous project work.

1. Public/Web server access is restricted to HTTP protocol from anywhere.
2. jumphost is accessible only on tcp/22 from administrator's host.
3. Private servers is not directly accessible from outside world.
4. SSH access to public and private servers is available through jumphost only
5. All of above restrictions are achieved through AWS security groups.

**As a part of this project, following additional security measures are implemented**

1. An IAM Policy is created that allows read-only access to EC2 and VPC.
2. An IAM Policy is created that allows full access to one S3 bucket specific to this project. All other S3 access requests are denied
3. Create a IAM role that allows to send logs to AWS Cloudwatch Logs.
4. Attach this role to jumphost and send all auth logs to Cloudwatch.
5. An Ansible playbook installs awslogs package on jumphost and also configures it.
6. Finally enable VPC Flow Logs to track IP flows.

## IAM Policy that allows read-only access to EC2 and VPC
- First a policy is created
- Then a group is created
- Policy is applied to the group.
- Finally user is created and added to the above group.

```
resource "aws_iam_policy" "ReadOnly" {
  name        = "ReadOnly"
  path        = "/"
  description = "For Users having readonly access to EC2 and VPC"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group" "ReadOnly" {
  name = "ReadOnly"
}

resource "aws_iam_group_policy_attachment" "ReadOnly" {
  group      = aws_iam_group.ReadOnly.name
  policy_arn = aws_iam_policy.ReadOnly.arn
}

resource "aws_iam_user" "John" {
  name = "John"
}

resource "aws_iam_group_membership" "ReadOnly" {
  name = "ReadOnly"
  users = [
    aws_iam_user.John.name
  ]
  group = aws_iam_group.ReadOnly.name
}

```


## IAM Policy that allows full access to one S3 bucket (for this project)
- First a policy is created
- Then a group is created
- Policy is applied to the group.
- Finally user is created and added to the above group.

```
resource "aws_iam_policy" "RestrictedS3" {
  name        = "RestrictedS3"
  path        = "/"
  description = "Allow full access to nadeem.networkinginpubliccloud bucket"

  policy = <<EOF
{ 
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::nadeem.networkinginpubclouds"           
        }
    ]
}
EOF   
}

resource "aws_iam_group" "RestrictedS3" {
  name = "RestrictedS3"
}

resource "aws_iam_group_policy_attachment" "RestrictedS3" {
  group      = aws_iam_group.RestrictedS3.name
  policy_arn = aws_iam_policy.RestrictedS3.arn
}
resource "aws_iam_user" "Tom" {
  name = "Tom"
}

resource "aws_iam_group_membership" "RestrictedS3" {
  name = "RestrictedS3"
  users = [
    aws_iam_user.Tom.name
  ]
  group = aws_iam_group.RestrictedS3.name
}
```

## IAM Role for AWS Logs
- an IAM Role is created for an EC2 instance
- A policy is applied to the role that allows logs to be sent to AWS Cloudwatch logs.

```
resource "aws_iam_role_policy" "CloudWatchLogs" {
  name = "CloudWatchLogs"
  role = aws_iam_role.CloudWatchLogs.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "CloudWatchLogs" {
  name = "CloudWatchLogs"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "CloudWatchLogs" {
  name = "CloudWatchLogs"
  role = aws_iam_role.CloudWatchLogs.name
}
```

## Adding role to the jumphost
This can be achived by adding following code to the Terraform resource for jumphost.

```
iam_instance_profile = aws_iam_instance_profile.CloudWatchLogs.name
```
ansible-playbook -i hosts --ssh-common-args '-F ssh-config' pb_webserver.yml

## Ansible inventory file
In previous project, I used AWS dynamic plugin to build Ansible hosts file. Here I took a different approach by using jinja template. Terraform's template rendering function is used to fill jumphost's public IP address.

```
resource "local_file" "hosts" {
  filename = "hosts"
  content = templatefile("hosts.template", {jumphost = aws_instance.jumphost.public_ip})
}
```

## ssh-config file 
I had to create a customized ssh-config file for Ansible's access to private and public servers through jumphost. This makes use of ProxyCommand. Again, I used Terraform to fill in the public IP of the jumphost.

```
resource "local_file" "ssh-config" {
  filename = "ssh-config"
  file_permission = "0644"
  content = templatefile("ssh-config.template", {jumphost = aws_instance.jumphost.public_ip})
}
```

## Ansible Playbook to install awslogs package to jumphost.
Amazon CloudWatch Logs can be used to monitor, store, and access log files from EC2 instances. I chose to use it for sending auth logs from jumphost. Ansible installs awslogs package, and configures it so that all messages in file /var/log/secure are sent to Cloudwatch. Note /var/log/secure is where centos keeps all sshd related logs. This playbook is described in file pb_jumphost.yml

```
ansible-playbook -i hosts --ssh-common-args '-F ssh-config' pb_jumphost.yml 
```

Here is how the login/logout logs look at Cloudwatch

```
Jun 9 09:49:16 ip-10-0-1-101 sshd[4915]: Accepted publickey for ec2-user from 37.210.173.150 port 7679 ssh2: RSA SHA256:j826sZJNqf5LXjyoar4sazCbX2GHXL9Wsr5

Jun  9 09:52:01 ip-10-0-1-101 sshd[4933]: Received disconnect from 37.210.173.150 port 7679:11: disconnected by user
Jun 9 09:52:01 ip-10-0-1-101 sshd[4933]: Disconnected from 37.210.173.150 port 7679
```
## Enable VPC Flow Logs
Create a CloudWatch Logs group "flows"

```
+resource "aws_cloudwatch_log_group" "flows" {
+  name = "flows"
+}
+
+resource "aws_flow_log" "flow_log" {
+  iam_role_arn    = aws_iam_role.CloudWatchLogs.arn
+  log_destination = aws_cloudwatch_log_group.flows.arn
+  traffic_type    = "ALL"
+  vpc_id          = aws_vpc.nl-vpc.id
+}
```