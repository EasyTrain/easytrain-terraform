#!/bin/bash

# Fetch Elastic IP using IMDSv2
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4`

echo "export PUBLIC_IP=$IP" >> /etc/environment