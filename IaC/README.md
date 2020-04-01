# Automating Cloud Deployments

There are various tools available to deploy infrastructure in public clouds. I started off with Ansible since I am most familiar with it. But soon I realized that, when using Ansible I need to take care of dependencies and order of execution. I started reading about Terraform and felt that this might be a better tool. Since it is free to use, I downloaded and gave it a try. It is well documented and easy to use. I think going forward I will continue to use it.

Here I have added a simple terraform code to generate AWS security groups in default VPC.
