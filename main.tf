provider "aws" {
  region  = "eu-central-1"
  profile = "easytrain"
}

locals {
  cidr-vpc = "10.0.0.0/16"
  cidr-all = "0.0.0.0/0"
  name     = "EasyTrain-"
  vpc-id   = aws_vpc.easytrain-vpc.id
  sg-id    = aws_security_group.easytrain-sg.id
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

resource "aws_security_group" "easytrain-sg" {
  vpc_id = local.vpc-id
  name = "${local.name}sg"

  tags = {
    Name = "${local.name}sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-ssh" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

  tags = {
    Name = "${local.name}igr-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-http" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 8081
  ip_protocol       = "tcp"
  to_port           = 8081

  tags = {
    Name = "${local.name}igr-http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-icmp" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 8
  ip_protocol       = "icmp"
  to_port           = 0

  tags = {
    Name = "${local.name}igr-icmp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-pg" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432

  tags = {
    Name = "${local.name}igr-pg"
  }
}

# Required to install openjdk-21-jdk, postgresql
resource "aws_vpc_security_group_egress_rule" "easytrain-egr-updates" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 1
  ip_protocol       = "tcp"
  to_port           = 65535

  tags = {
    Name = "${local.name}egr-updates"
  }
}

resource "aws_vpc_security_group_egress_rule" "easytrain-egr-email" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 587
  ip_protocol       = "tcp"
  to_port           = 587

  tags = {
    Name = "${local.name}egr-updates"
  }
}

resource "aws_instance" "easytrain-ec2" {
  # Ubuntu Server 24.04 LTS
  ami                         = var.ami-id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.easytrain-subnet-pub1.id
  key_name                    = "ssh_aws_easytrain_ed25519"
  vpc_security_group_ids      = ["${local.sg-id}"]

  tags = {
    Name = "${local.name}ec2"
  }
}

resource "aws_eip" "easytrain-eip" {
  instance = aws_instance.easytrain-ec2.id
  depends_on = [ aws_internet_gateway.easytrain-ig ]
}