terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################################################
# Internet Gateway for Client

resource "aws_internet_gateway" "client_igw" {
  vpc_id = aws_vpc.client_vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-igw"
  })
}

############################################################
# VPC for Client

resource "aws_vpc" "client_vpc" {
  cidr_block = var.client_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-vpc"
  })
}
############################################################
# Client Subnet

resource "aws_subnet" "client-public-subnet" {
  vpc_id                  = aws_vpc.client_vpc.id
  cidr_block              = values(var.client_subnet_cidr)[0]
  availability_zone       = keys(var.client_subnet_cidr)[0]
  map_public_ip_on_launch = true

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-client-public-subnet"
  })
}

############################################################
# Route Tables

resource "aws_route_table" "client-rt-public" {
  vpc_id = aws_vpc.client_vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-client-rt-public"
  })
}

# Associate Public Subnets with Route Table for Internet Gateway
resource "aws_route_table_association" "client-rt-to-public-subnet" {
  subnet_id = aws_subnet.client-public-subnet.id
  route_table_id = aws_route_table.client-rt-public.id
}

############################################################
# Client Route Entries

resource "aws_route" "client-public-allipv4" {
  route_table_id         = aws_route_table.client-rt-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.client_igw.id
}

resource "aws_route" "client-public-allowipv6" {
  route_table_id              = aws_route_table.client-rt-public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.client_igw.id
}