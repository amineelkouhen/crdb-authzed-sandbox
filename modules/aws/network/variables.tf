variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets_cidrs" {
  description = "CIDR blocks for the subnets in each zone"
  type        = map
}