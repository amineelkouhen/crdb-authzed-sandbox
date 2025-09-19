terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
############################################################
# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-igw"
  })
}

############################################################
# VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-vpc"
  })  
}

############################################################
# Subnets

resource "aws_subnet" "public-subnets" {
  count                   = length(var.subnets_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = values(var.subnets_cidrs)[count.index]
  availability_zone       = keys(var.subnets_cidrs)[count.index]
  map_public_ip_on_launch = true
  
  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-public-subnet-${count.index}"
  })
}

############################################################
# Route Tables

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.vpc.id
  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-rt-public"
  })
}

# Associate the main route table to the VPC
resource "aws_main_route_table_association" "rt-main" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.rt-public.id
}

# Associate Public Subnets with Route Table for Internet Gateway
resource "aws_route_table_association" "rt-to-public-subnet" {
  count = length(var.subnets_cidrs)
  subnet_id = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.rt-public.id
}

############################################################
# Route Entries

resource "aws_route" "public-allipv4" {
  route_table_id         = aws_route_table.rt-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "public-allowipv6" {
  route_table_id              = aws_route_table.rt-public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

############################################################
# Creates AWS load balancer
resource "aws_lb" "nlb" {
  name_prefix = "nlb-"
  internal           = false
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.public-subnets : subnet.id]

  security_groups = tolist([aws_security_group.allow-global.id])

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-nlb"
  })
}

# Creates target groups
resource "aws_lb_target_group" "sql_lb_tg" {
  name_prefix = "sq-tg-"
  target_type = "instance"
  port        = 26257
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-sql-lb-tg"
  })
}

resource "aws_lb_target_group" "console_lb_tg" {
  name_prefix = "cl-tg-"
  target_type = "instance"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-con-lb-tg"
  })
}

# network load balancer listeners - port 26257 & 8080 forwarded
resource "aws_lb_listener" "sql_lb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "26257"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sql_lb_tg.arn
  }
}

resource "aws_lb_listener" "console_lb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "8080"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.console_lb_tg.arn
  }
}