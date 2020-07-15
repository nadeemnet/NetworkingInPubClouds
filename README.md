This repository is the result of a course I took related to Networking in Public Clouds. The course details are available at the following link.

https://www.ipspace.net/PubCloud/

Each directory contains a separate project from the course. As we progress through the course, we built on top of the previous project. The directory list below shows the chronological order the projects were assigned. 

1. requirements
2. IaC
3. network
4. webServer
5. networkv6
6. security

All of infrastructure deployments were fully automated using Terraform and Ansible

## PUBLIC CLOUD REQUIREMENTS

* Compute options should meet diverse memory and cpu requirements
* Compute options should serve elastic demands of the business
* Different storage tiers should be available as per business needs.
* Traffic between existing data center and cloud should be encrypted
* Roles based access should be available for different business units
* Cloud offering should incorporate Infrastructure as code principles.
* Resource usage cost should be available in near real time.
* Traffic into and out of cloud should be controlled
* Cloud should provide DHCP and DNS services
* Cloud should offer different segments with the ability to isolate from each other.
* Hosts in the cloud should have connectivity to data center as well as Internet (local breakout)
* Cloud should offer stateful firewall services
* Cloud should offer audit-trail of the activities performed.
* Cloud should offer presence in different geographical areas.


##  INFRASTRUCTURE DEPLOYMENT TOOL SELECTION

There are various tools available to deploy infrastructure in public clouds. I started off with Ansible since I am most familiar with it. But soon I realized that, when using Ansible I need to take care of dependencies and order of execution. I started reading about Terraform and felt that this might be a better tool. Since it is free to use, I downloaded and gave it a try. It is well documented and easy to use. I think going forward I will continue to use it.


##  AWS VPC, SUBNETS, NAT GATEWAY AND SECURITY GROUPS

1. Create an AWS VPC and add one public subnet and one private subnet
2. Create a route table for public subnet and add an Internet Gateway to it.
3. Create a route table for private subnet and add a NAT Gateway to it.
4. Create different security groups, detail will be later in the document.
5. Deploy a jumphost in public subnet and ssh access is allowed from admin host only.
6. Deploy a web server in public subnet and allow tcp/80 from anywhere.
7. Deploy a backend server (aka private server) that can only talk to web server.
8. jumphost is allowed to talk (tcp/22) to both web server and backend server.

##  WEB SERVER

1. An Ubuntu VM is deployed in AWS cloud using Terraform.
2. AWS Security Groups are created using Terraform.
3. These Security Groups limit incoming traffic to http and ssh
4. All outbound traffic is allowed
5. "images" and "files" directories are uploaded to S3 buckets using Terraform
6. images directory contains all the images used in the website
7. files directory backs up all apache related config files.
8. A record is created in AWS Route53 for the website.
9. After VM is ready, Ansible is used to install and configure Apache webserver.


##  IPv6

1. Enable IPv6 in VPC
2. Enable IPv6 in Public and Private Subnet
3. In the Public Subnet Route Table, create a default route for IPv6.
4. Add IPv6 cidr blocks in the security groups.
5. Deploy a dual stacked jumphost in public subnet and ssh access is allowed from admin host only.
6. Deploy a dual stacked web server in public subnet and allow tcp/80 from anywhere.
7. Deploy a dual backend server (aka private server) that can only talk to web server.
8. jumphost is allowed to talk (tcp/22) to both web server and backend server.


##  SECURITY

1. Public/Web server access is restricted to HTTP protocol from anywhere.
2. jumphost is accessible only on tcp/22 from administrator's host.
3. Private servers is not directly accessible from outside world.
4. SSH access to public and private servers is available through jumphost only
5. All of above restrictions are achieved through AWS security groups.
6. An IAM Policy is created that allows read-only access to EC2 and VPC.
7. An IAM Policy is created that allows full access to one S3 bucket specific to this project. All other S3 access requests are denied
8. Create a IAM role that allows to send logs to AWS Cloudwatch Logs.
9. Attach this role to jumphost and send all auth logs to Cloudwatch.
10. An Ansible playbook installs awslogs package on jumphost and also configures it.
11. Finally enable VPC Flow Logs to track IP flows.
