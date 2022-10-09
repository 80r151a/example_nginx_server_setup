#!/bin/bash


### The server uses Debian 11
## Before executing the script, make sure
# Requires to be sshpass and ssh-copy-id installed
# Before executing the script, you need to log in to the server at least once.
## Don't forget to change the root password after executing the script
## After executing the script, access is possible only with the ssh key
## While the script is running, you need to enter the password of the server root user (to send the ssh rsa key) and give permission to activate the ufw firewall (at this time the script will be suspended)


## Access
# Server address and password root
ip_server=81.163.31.36
#
# A pair of username and server address for ssh login
remote_exection=root@$ip_server
#
# Dron SSH pub key
dronpiton_pubkey=$(echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAl1yWN+7RKhQ1EDVx+9/mpHf0qgKmf5DwuPCMssxEAiicm0mQU6aOKfqnbiDZGyK8CST+Dlljv2KTXGRG5zWFtl3N9TG0TGtGZrOsW5HzZBWvRzN9pv7JG+8pSSCZ+1Evs4OjVw09bXhtg5A2i9V4BNemrIu2rwbsG85d+HW5kAKN0fyp1qbE1mo9HPYqHb5WTpJqvh2he5/j2hgx3/3yvN5gE3txYCMtBeSdaEikKaXudI5Y8ElJY8F3aw/ZtUX9IJda+4cZ/h059xYdmuE60MvcQoMm93JBG4cExxQQiv7VYnLlvIfqvtj1VOSHSrXLe+k6KMCbqNyP90m6cZGZkw== agolubev')

## Variables with paths
# Path to static html page
path_to_html_page=/home/borisla/index.html


## Setting up ssh login by key only
# Adding a local (from the place where the script was launched) key
ssh-copy-id -i ~/.ssh/id_rsa.pub $remote_exection
#
# Adding a Dronepithon key 
ssh $remote_exection "echo $dronpiton_pubkey >> /root/.ssh/authorized_keys"
#
# Disabling password login
ssh $remote_exection sed -i 's/PasswordAuthentication\ yes/PasswordAuthentication\ no/' /etc/ssh/sshd_config

## Installing the required packages
# Downloading the latest information about software metapackages
ssh $remote_exection apt update
#
## Install nginx and ufw
ssh $remote_exection apt install nginx ufw -y


## Firewall setup with ufw
# Allow port http (80)
ssh $remote_exection ufw allow http
#
# Allow ssh port (22)
ssh $remote_exection ufw allow ssh
#
# Turning on the firewall
ssh $remote_exection ufw enable

## Setting up nginx
# Enable nginx autostart
ssh $remote_exection systemctl enable nginx
#
# Creating a сontent storage directory
ssh $remote_exection mkdir -p /data/www
#
# Sending html page to server
scp $path_to_html_page $remote_exection:/data/www/
#
# Create a virtual host file
ssh $remote_exection touch /etc/nginx/sites-available/bashgrandma.conf
#
# We create a symbolic link to this virtual host from the sites-available directory to the sites-enabled directory so that nginx serves it
ssh $remote_exection ln -s /etc/nginx/sites-available/bashgrandma.conf /etc/nginx/sites-enabled/
#
# Setting up a virtual host (sending parameters to a configuration file)
ssh $remote_exection "echo -e 'server {\n    listen [::]:80;\n    listen 80;\n    access_log  /var/log/nginx/bashgrandma/access.log;\n    error_log   /var/log/nginx/bashgrandma/error.log;\n\n    server_name 81.163.31.36;\n\n    root /data/www;\n    index index.html;\n}' >> /etc/nginx/sites-available/bashgrandma.conf"
#
# Reloading the nginx config file
ssh $remote_exection nginx -s reload

## Completion message
echo 'This script did its job the best it could and it says goodbye to you!'
