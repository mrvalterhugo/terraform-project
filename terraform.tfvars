#Change this values to yours
aws_profile      = "default"
aws_region       = "eu-west-2"
vpc_cidr         = "192.168.0.0/16"
localip          = ["0.0.0.0/0"]
key              = "You-AWS-SSH-Key-Name"
instance_type    = "t2.micro"
domain           = "example.com"
domain-zone-id   = "64564646464664646example"
cloudflare_token = "f5sdf4sd54f5sd4fexample"
user_data        = "userdata.sh"

apps = {
  docker  = "docker"
  pihole  = "pihole"
  nginx   = "nginx"
  code    = "code"
  whoogle = "google"
}

cidrs = {
  docker-subnet = "192.168.10.0/24"
}

#For AWS London Region
images = {
  debian       = "ami-0ef2c681c6c4ff0e9"
  ubuntu       = "ami-05c424d59413a2876"
  amazon-linux = "ami-0a669382ea0feb73a"
  redhat       = "ami-0fc841be1f929d7d1"
}