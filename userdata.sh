#!/bin/bash

##Set Hostname
sudo hostnamectl set-hostname docker-server

sudo apt install -y apt-transport-https && echo 'apt-transport-https has been installed ###############' && sleep 3
sudo apt install -y ca-certificates && echo 'ca-certificates has been installed #######################' && sleep 3
sudo apt install -y curl && echo 'curl has been installed #############################################' && sleep 3
sudo apt install -y gnupg-agent && echo 'gnupg-agent has been installed ###############################' && sleep 3
sudo apt install -y software-properties-common && echo 'software-properties-common has been installed ' && sleep 3
sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' && echo 'docker repo has been installed ########' && sleep 3
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && echo 'key has been downloaded ######' && sleep 3
sudo apt-key fingerprint 0EBFCD88 && echo 'fingerprint key has been add ###############################' && sleep 3
sudo apt update && echo 'APT updated ##################################################################' && sleep 3
sudo apt install docker-ce -y && echo 'Docker-ce installed ############################################' && sleep 3
sudo apt install docker-ce-cli -y && echo 'Docker-ce-cli installed ####################################' && sleep 3
sudo apt install containerd.io -y && echo 'containerd.io installed ####################################' && sleep 3
sudo apt install docker-compose -y && echo 'docker-compose installed ##################################' && sleep 3
sudo apt install jq -y && echo 'jq installed ##########################################################' && sleep 3
sudo curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && echo 'AWS-CLI downloaded ####' && sleep 3
sudo apt install -y unzip && echo 'Unzip has been installed ###########################################' && sleep 3
sudo unzip awscliv2.zip && echo 'AWS-CLI unzipped #####################################################' && sleep 3
sudo ./aws/install && echo 'AWS-CLI installed #########################################################' && sleep 3
rm -f aws awscliv2.zip
echo 'All Packages have been installed ################################################################' && sleep 3

#Create folders to be used by containers
mkdir -p ~/configs/{netdata,pihole,nginx,guacamole,syncthing,portainer,whoogle,cloudflare,code}

#Create docker file inside folders

#######Portainer#######
cat << 'EOF' > ~/configs/portainer/docker-compose.yaml
version: "3"
services:
  portainer:
    container_name: portnainer
    image: portainer/portainer-ce
    ports:
      - "8000:8000"
      - "9000:9000"
    # Volumes store your data between container upgrades
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
      - './portainer_data:/data portainer/portainer-ce'
    restart: always
EOF
######Nginx - Proxy Manager#########
cat << 'EOF' > ~/configs/nginx/docker-compose.yaml
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '7779:81'
      - '443:443'
    volumes:
      - ./config.json:/app/config/production.json
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
      - ./var:/var/logs
  db:
    restart: unless-stopped
    image: 'jc21/mariadb-aria:10.4'
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./data/mysql:/var/lib/mysql 
EOF
cat << 'EOF' > ~/configs/nginx/config.json
{
  "database": {
    "engine": "mysql",
    "host": "db",
    "name": "npm",
    "user": "npm",
    "password": "npm",
    "port": 3306
  }
}
EOF

#####PiHole#############
cat << 'EOF' >  ~/configs/pihole/docker-compose.yaml
version: "3"
# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "7778:80/tcp"
      - "7780:443/tcp"
    environment:
      TZ: 'Europe/London'
  # 'set a secure password here'
      WEBPASSWORD: 'password'
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole/:/etc/pihole/'
      - './etc-dnsmasq.d/:/etc/dnsmasq.d/'
    # Recommended but not required (DHCP needs NET_ADMIN)
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
EOF
#########Whoogle##########
cat << 'EOF' > ~/configs/whoogle/docker-compose.yaml
---
version: "2"
services:
  whoogle:
    image: benbusby/whoogle-search:latest
    container_name: whoogle
    ports:
      - 7781:5000
    restart: unless-stopped
EOF
#########Syncthing##########
cat << 'EOF' > ~/configs/syncthing/docker-compose.yaml
---
version: "2.1"
services:
  syncthing:
    image: linuxserver/syncthing
    container_name: syncthing
    hostname: syncthing #optional
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - ./config:/config
      - ./data:/data1
    ports:
      - 8384:8384
      - 22000:22000
      - 21027:21027/udp
    restart: unless-stopped
EOF
#########Netdata#######
cat << 'EOF' > ~/configs/netdata/docker-compose.yaml
version: '3'
services:
  netdata:
    image: netdata/netdata
    container_name: netdata
    hostname: docker-server # set to fqdn of host
    ports:
      - 19999:19999
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - netdataconfig:/etc/netdata
      - netdatalib:/var/lib/netdata
      - netdatacache:/var/cache/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro

volumes:
  netdataconfig:
  netdatalib:
  netdatacache:
EOF

#########Code Server######
cat << 'EOF' > ~/configs/code/docker-compose.yaml
---
version: "2.1"
services:
  code-server:
    image: linuxserver/code-server
    container_name: code-server
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - PASSWORD=123456 #optional
      - SUDO_PASSWORD=123456 #optional
     # - PROXY_DOMAIN=code-server.example.com #optional
    volumes:
      - ./config:/config
    ports:
      - 8443:8443
    restart: unless-stopped
EOF

#########Guacamole#######
cat << 'EOF' > ~/configs/guacamole/docker-compose.yaml
version: "2"
services:
  guacamole:
    image: oznu/guacamole
    container_name: guacamole
    volumes:
      - ./config:/config
    ports:
      - 8080:8080
    environment:
      EXTENSIONS: 'auth-totp'
    restart: unless-stopped
EOF

#######CloudFlare#######
cat << 'EOF' > ~/configs/cloudflare/docker-compose.yaml
version: '2'
services:
  cloudflare-ddns:
    image: oznu/cloudflare-ddns:latest
    restart: always
    environment:
      - API_KEY=xxxxxxx
      - ZONE=example.com
      - SUBDOMAIN=subdomain
      - PROXIED=false
EOF

#Start all containers
echo "##################"
echo "Downloading and starting containers"
echo "##################"
sleep 3
sudo docker-compose -f ~/configs/nginx/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/portainer/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/netdata/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/pihole/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/syncthing/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/whoogle/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/cloudflare/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/code/docker-compose.yaml up -d
echo "##################"
echo "##################"
echo "Congrats, your new docker server is now provisioned"
echo "##################"
echo "##################"
sudo docker ps
sleep 10