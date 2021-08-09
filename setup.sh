#!/bin/bash
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install unzip awscli -y
apt-get install apache2 -y
systemctl start apache2.service
cd /var/www/html
aws s3 cp s3://udacity-demo-123/udacity.zip .
unzip -o udacity.zip
