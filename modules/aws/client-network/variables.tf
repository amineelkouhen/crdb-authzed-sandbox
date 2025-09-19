variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "client_vpc_cidr" {
  description = "CIDR block for the Client VPC"
  type        = string
}

variable "client_subnet_cidr" {
  description = "The availbaility zone with the subnet cidr, in which this bastion will be created"
  type        = map
}