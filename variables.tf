variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}
variable "localip" {}
variable "key" {}
variable "instance_type" {}
variable "user_data" {}
variable "domain" {}
variable "domain-zone-id" {}
variable "cloudflare_token" {}

variable "apps" {
  type = map
}
variable "images" {
  type = map
}

variable "cidrs" {
  type = map
}

