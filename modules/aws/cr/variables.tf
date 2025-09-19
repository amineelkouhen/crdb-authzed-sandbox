variable "name" {
  description = "Deployment name, also used as prefix for resources"
  type        = string
}

variable "subnets" {
  description = "list of subnets"
  type        = list
}

variable "region" {
  description = "Region Name"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security groups to attached to the node"
  type        = list(string)
}

variable "machine_image" {
  description = "AWS EC2 machine image"
  type        = string
}

variable "machine_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_key_name" {
  description = "AWS EC2 Keypair's name"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}

variable "ssh_user" {
  description = "SSH linux user"
  type        = string
}

variable "worker_count" {}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "cockroach_release" {
  description = "CRDB Release"
  type        = string
}

variable "sql_load_balancer_arn"{
  description = "Load Balancer ARN for Port 26257"
  type        = string
}

variable "console_load_balancer_arn"{
  description = "Load Balancer ARN for Port 8080"
  type        = string
}

variable "boot_disk_size" {
  description = "Volume Size"
  type        = number
}

variable "cluster_join_ips" {
  description = "IP list of nodes joining the CRDB cluster"
  type        = list
}

variable "init" {
  description = "Initialize Cluster"
  type        = bool
}

variable "boot_disk_type" {
  description = "Volume Type"
  type        = string
}