# create an IAM policy that allows read only access to EC2 and VPC
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

resource "aws_iam_access_key" "John" {
  user = aws_iam_user.John.name
}

output "RO_ACC_KEY" {
  value = aws_iam_access_key.John.id
}

output "RO_SEC_KEY" {
  value = aws_iam_access_key.John.secret
}

# Create an IAM policy to allow full access to a particular s3 bucket
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

resource "aws_iam_access_key" "Tom" {
  user = aws_iam_user.Tom.name
}

output "TOM_ACC_KEY" {
  value = aws_iam_access_key.Tom.id
}

output "TOM_SEC_KEY" {
  value = aws_iam_access_key.Tom.secret
}


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
      },
       {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "vpc-flow-logs.amazonaws.com"
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