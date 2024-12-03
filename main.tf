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

resource "aws_subnet" "easytrain-subnet-pub2" {
  vpc_id            = local.vpc-id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1b"


  tags = {
    Name = "${local.name}subnet-pub2"
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

resource "aws_route_table_association" "easytrain-rta-pub1" {
  route_table_id = aws_route_table.easytrain-rt.id
  subnet_id      = aws_subnet.easytrain-subnet-pub1.id
}

resource "aws_route_table_association" "easytrain-rta-pub2" {
  route_table_id = aws_route_table.easytrain-rt.id
  subnet_id      = aws_subnet.easytrain-subnet-pub2.id
}

resource "aws_security_group" "easytrain-sg" {
  vpc_id = local.vpc-id
  name   = "${local.name}sg"

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

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-alb" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {
    Name = "${local.name}igr-http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-https" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = {
    Name = "${local.name}igr-https"
  }
}

resource "aws_vpc_security_group_ingress_rule" "easytrain-igr-http" {
  security_group_id = local.sg-id
  cidr_ipv4         = local.cidr-all
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080

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

resource "aws_launch_template" "easytrain-lt" {
  name          = "easytrain-lt"
  image_id      = var.ami-id
  instance_type = "t2.micro"
  key_name      = "ssh_aws_easytrain_ed25519"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.easytrain-subnet-pub1.id
    security_groups             = ["${local.sg-id}"]
  }

  user_data = filebase64("user_data.sh")

  tags = {
    Name = "${local.name}ec2"
  }
}

resource "aws_autoscaling_group" "easytrain-asg" {
  availability_zones = [aws_subnet.easytrain-subnet-pub1.availability_zone]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  default_cooldown = 180

  launch_template {
    id      = aws_launch_template.easytrain-lt.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "easytrain-tg" {
  name     = "easytrain-lb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.easytrain-vpc.id

  tags = {
    Name = "${local.name}tg"
  }
}

resource "aws_lb" "easytrain-lb" {
  name            = "easytrain-lb"
  security_groups = ["${local.sg-id}"]
  subnets         = [aws_subnet.easytrain-subnet-pub1.id, aws_subnet.easytrain-subnet-pub2.id]

  tags = {
    Name = "${local.name}lbg"
  }
}

resource "aws_lb_listener" "easytrain-lb-listener" {
  load_balancer_arn = aws_lb.easytrain-lb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "easytrain-lb-listener-https" {
  load_balancer_arn = aws_lb.easytrain-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:eu-central-1:905418204334:certificate/d4e6f897-23dc-4125-ac22-2ab7076e4d3f"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.easytrain-tg.arn
  }
}

resource "aws_autoscaling_attachment" "easytrain-asa" {
  autoscaling_group_name = aws_autoscaling_group.easytrain-asg.id
  lb_target_group_arn    = aws_lb_target_group.easytrain-tg.arn
}

resource "aws_route53_record" "easytrain_live_a_record" {
  zone_id = "Z05842423SR64FMV7ZQFU"
  name    = "easytrain.live"
  type    = "A"

  alias {
    name                   = aws_lb.easytrain-lb.dns_name
    zone_id                = aws_lb.easytrain-lb.zone_id
    evaluate_target_health = true
  }
}
