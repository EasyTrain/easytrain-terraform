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

resource "aws_internet_gateway" "easytrain-ig" {
  vpc_id = local.vpc-id

  tags = {
    Name = "${local.name}ig"
  }
}

resource "aws_route_table" "easytrain-rt" {
  vpc_id = local.vpc-id

  route {
    cidr_block = local.cidr-vpc
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.easytrain-ig.id
  }

  tags = {
    Name = "${local.name}ig"
  }
}

resource "aws_route_table_association" "easytrain-rta" {
  route_table_id = aws_route_table.easytrain-rt.id
  subnet_id      = aws_subnet.easytrain-subnet-pub1.id
}
