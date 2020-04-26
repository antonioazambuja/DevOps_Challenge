#!/bin/bash

apt update -y
apt install curl unzip wget -y
apt install build-essential -y

echo "-------------- > Install Python, pip and aws-cli < --------------"
apt install python3.7 -y
apt install python3-pip -y
pip3 install awscli --upgrade --user

echo "-------------- > Install Packer < --------------"
wget https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip -O packer.zip
unzip packer.zip -d /usr/local/bin/
rm -r packer.zip

echo "-------------- > Install Terraform < --------------"
wget https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_linux_amd64.zip -O terraform.zip
unzip terraform.zip -d /usr/local/bin
rm -r terraform.zip

echo "-------------- > Install Docker < --------------"
apt update -y
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update -y
apt-cache policy docker-ce -y
apt install docker-ce -y
usermod -aG docker ${USER}

echo "-------------- > Install Java 8 (openjdk-8) < --------------"
add-apt-repository ppa:openjdk-r/ppa -y
apt-get update -y
apt-get install openjdk-8-jdk -y

echo "-------------- > Install Jenkins < --------------"
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update -y
apt-get install jenkins -y
service jenkins status

exit 0
