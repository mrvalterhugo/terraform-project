# Terraform-project
An IaC project that I have made while studying **Terraform**.

For this porject, you will need an **AWS** and a **CloudFlare** account.

You can either run it on a AWS EC2 instance with an Admin **IAM Role** attached to it or run from any **Linux 
terminal** with AWS Access and Secret key.

You need to **install** Terraform on the machine this will be ran.

For this project I am using CloudFlare as my DNS management, but my domain is registered in **Route53**.

You can replace the CloudFlare resource for Route53.

The **user-data** can be replaced by any script/commands that you want to be execute in the first boot.

Resources that will be **created**:
- VPC
- Internet Gateway
- Route Table
- Subnet
- Security Group
- Cloud Flare DNS entries
- Terraform outputs.
> Please note that you need to change the terraform.tfvars for you own use.