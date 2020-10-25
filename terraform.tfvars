#Change this values to yours
aws_profile      = "default"
aws_region       = "eu-west-2"
vpc_cidr         = "192.168.0.0/16"
localip          = ["0.0.0.0/0"]
key_name         = "dockerk"
user_name        = "admin"
public_key_path  = "~/docker.pem"
instance_type    = "t2.micro"
domain           = "example.com"
domain-zone-id   = "92899841domain-zone-id-aa4c7f70"
cloudflare_token = "2Qf7ZDcloud-flare-token-kPrmHeAS"
user_data        = "userdata.sh"

apps = {
  docker  = "docker2"
  pihole  = "pihole2"
  nginx   = "nginx2"
  code    = "code2"
  whoogle = "google2"
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