terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

#------ VPC -------

resource "aws_vpc" "docker_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "docker_vpc"
  }
}

#----- Internet Gateway -----
resource "aws_internet_gateway" "docker_internet_gateway" {
  vpc_id = aws_vpc.docker_vpc.id
}

#--------Route Tables -------

resource "aws_route_table" "docker_public_rt" {
  vpc_id = aws_vpc.docker_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.docker_internet_gateway.id
  }
  tags = {
    Name = "docker_public"
  }
}

resource "aws_default_route_table" "docker_private_rt" {
  default_route_table_id = aws_vpc.docker_vpc.default_route_table_id

  tags = {
    Name = "docker_private"
  }
}

#-------- Subnets ---------

resource "aws_subnet" "docker_public_subnet_1" {
  vpc_id                  = aws_vpc.docker_vpc.id
  cidr_block              = var.cidrs["docker-subnet"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "docker_public__subnet_1"
  }
}
#-------- Subnet Associations ------

resource "aws_route_table_association" "docker_public_1_assoc" {
  subnet_id      = aws_subnet.docker_public_subnet_1.id
  route_table_id = aws_route_table.docker_public_rt.id
}

#------- Public Security Group

resource "aws_security_group" "docker_public_sg" {
  name        = "docker_public_sg"
  description = "Used for the docker instance for public access"
  vpc_id      = aws_vpc.docker_vpc.id

  #HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTPS
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #SSH
  ingress {
    description = "Allow SSH - Local IP Only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Allow my IP only
    cidr_blocks = var.localip
  }

  #Nginx Admin Portal
  ingress {
    description = "Allow NGINX admin port"
    from_port   = 7779
    to_port     = 7779
    protocol    = "tcp"
    # Allow my IP only
    cidr_blocks = var.localip
  }

  #DNS
  ingress {
    description = "Allow DNS from Local IP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    # Allow my IP only
    cidr_blocks = var.localip
  }

  #DNS
  ingress {
    description = "Allow DNS from Local IP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    # Allow my IP only
    cidr_blocks = var.localip
  }

  #DNS
  ingress {
    description = "Allow DNS from Local IP"
    from_port   = 67
    to_port     = 67
    protocol    = "tcp"
    # Allow my IP only
    cidr_blocks = var.localip
  }

  #DNS
  ingress {
    description = "Allow DNS from Local IP"
    from_port   = 67
    to_port     = 67
    protocol    = "udp"
    # Allow my IP only
    cidr_blocks = var.localip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Docker_public_SG"
  }

}

#-------EC2-----

resource "aws_instance" "docker-ec2" {
  ami           = var.images["debian"]
  instance_type = var.instance_type
  root_block_device {
    volume_size = 30
  }

  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.docker_public_sg.id
  ]
  subnet_id                   = aws_subnet.docker_public_subnet_1.id
  associate_public_ip_address = true
  tags = {
    Name = "docker-server"
  }

  connection {
    type        = "ssh"
    user        = var.user_name
    private_key = file(var.public_key_path)
    host        = aws_instance.docker-ec2.public_ip
  }
  provisioner "remote-exec" {
    script = var.user_data
  }


}


#------ Cloud Flare DNS -------

provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "cloudflare_record" "prod" {
  zone_id    = var.domain-zone-id
  name       = "prod"
  proxied    = false
  type       = "A"
  value      = aws_instance.docker-ec2.public_ip
  depends_on = [aws_instance.docker-ec2]
}

resource "cloudflare_record" "docker" {
  zone_id    = var.domain-zone-id
  name       = var.apps["docker"]
  proxied    = false
  value      = cloudflare_record.prod.hostname
  type       = "CNAME"
  depends_on = [cloudflare_record.prod]
}

resource "cloudflare_record" "pihole" {
  zone_id    = var.domain-zone-id
  name       = var.apps["pihole"]
  proxied    = false
  value      = cloudflare_record.prod.hostname
  type       = "CNAME"
  depends_on = [cloudflare_record.prod]
}

resource "cloudflare_record" "nginx" {
  zone_id    = var.domain-zone-id
  name       = var.apps["nginx"]
  proxied    = false
  value      = cloudflare_record.prod.hostname
  type       = "CNAME"
  depends_on = [cloudflare_record.prod]
}

resource "cloudflare_record" "whoogle" {
  zone_id    = var.domain-zone-id
  name       = var.apps["whoogle"]
  proxied    = false
  value      = cloudflare_record.prod.hostname
  type       = "CNAME"
  depends_on = [cloudflare_record.prod]
}

resource "cloudflare_record" "code" {
  zone_id    = var.domain-zone-id
  name       = var.apps["code"]
  proxied    = false
  value      = cloudflare_record.prod.hostname
  type       = "CNAME"
  depends_on = [cloudflare_record.prod]
}

#Outputs
output "docker-public-ip" {
  value = aws_instance.docker-ec2.public_ip
}
output "docker-private-ip" {
  value = aws_instance.docker-ec2.private_ip
}
output "Code" {
  value = cloudflare_record.code.hostname
}

output "Docker" {
  value = cloudflare_record.docker.hostname
}
output "Nginx" {
  value = cloudflare_record.nginx.hostname
}
output "Pihole" {
  value = cloudflare_record.pihole.hostname
}
output "Prod" {
  value = cloudflare_record.prod.hostname
}
output "Whoogle" {
  value = cloudflare_record.whoogle.hostname
}