#!/bin/sh

export accountId=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep accountId| awk '{print $3}'|sed  's/"//g'|sed 's/,//g')
export awsRegion=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region| awk '{print $3}'|sed  's/"//g'|sed 's/,//g')
sudo sed -i "s/accountId/$accountId/g" "/tmp/awslogs.conf"
sudo sed -i "s/awsRegion/$awsRegion/g" "/tmp/awslogs.conf"
sudo yum install awslogs -y
sudo rm -f /etc/awslogs/awslogs.conf
sudo mv /tmp/awslogs.conf /etc/awslogs/awslogs.conf
sudo service awslogsd start
sudo systemctl enable awslogsd