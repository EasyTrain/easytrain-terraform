![](images/easytrain-terraform.png)

# EasyTrain-Terraform

Terraform templates that provision AWS infrastructure for [easytrain/applicaion](https://github.com/EasyTrain/application) project.

This project is deployed on AWS at [Easytrain.live](https://easytrain.live/)

## AWS Architecture

![AWS architecture](images/easytrain.drawio.png)

## Description

The Terraform main.tf file provisions the following AWS resources:
- VPC in the eu-central-1 region
- Public subnet in the eu-central-1a availability zone
- Routing table and internet gateway
- An EC2 instance and a security group
  - Security Group ingress/egress rules:
    - SSH
    - HTTP (required by loadl balancer) 
    - Port 587 (required to send emails out)
- Load Balancer
- Route53 hosted zone
  - A record that points to the public IP

## Getting Started

### Dependencies

This requires Terraform version >=1.8.5 and the AWS provider version ~>5.54.1.

## Terraform Files
```
├── versions.tf
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

