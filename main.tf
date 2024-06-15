provider "aws" {
  region  = "eu-central-1"
  profile = "easytrain"
}

locals {
  cidr-vpc = "10.0.0.0/16"
  name     = "EasyTrain-"
  vpc-id   = aws_vpc.easytrain-vpc.id
}


resource "aws_vpc" "easytrain-vpc" {
  cidr_block           = local.cidr-vpc
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}vpc"
  }
}

resource "aws_subnet" "easytrain-subnet-pub1" {
  vpc_id            = local.vpc-id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-central-1a"


  tags = {
    Name = "${local.name}subnet-pub1"
  }
}
