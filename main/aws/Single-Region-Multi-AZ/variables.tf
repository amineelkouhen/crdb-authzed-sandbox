variable "deployment_name" {
  description = "Deployment Name"
  # No default
  # Use CLI or interactive input.
}

variable "aws_access_key" {
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
}

variable "aws_session_token" {
  description = "AWS Session Token"
}

variable "regions" {
  default = ["us-east-1"]
}

variable "crdb_vpc_cidr" {
  default = ["10.1.0.0/16"]
}

variable "crdb_subnets" {
  default = [{
    us-east-1a = "10.1.1.0/24"
    us-east-1b = "10.1.2.0/24"
    us-east-1c = "10.1.3.0/24"
  }]
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  default = "~/.ssh/id_rsa"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "crdb_volume_size" {
  default = 200
}

variable "crdb_volume_type" {
  default = "gp3"
}

// other optional edits *************************************
variable "crdb_cluster_size" {
  # Here we will create a 9-nodes cluster in one region
  default = [3]
}

// other possible edits *************************************
variable "crdb_release" {
  default = "https://binaries.cockroachdb.com/cockroach-v24.3.8.linux-amd64.tgz"
}

variable "crdb_machine_type" {
  default = "m5.xlarge"
}

variable "crdb_machine_images" {
  // Ubuntu 24.04 LTS
  default = ["ami-04b70fa74e45c3917"]
}

variable "env" {
  default = "us"
}

//// Client Configuration

variable "client_vpc_cidr" {
  default = "172.71.0.0/16"
}

variable "client_region" {
  default = "us-west-2"
}

variable "client_subnet" {
  type = map
  default = {
    us-west-2a = "172.71.1.0/24"
  }
}

variable "client_machine_type" {
  default = "m6a.large"
}

variable "client_machine_image" {
  // Ubuntu 24.04 LTS
  default = "ami-0cf2b4e024cdb6960"
}

#variable "authzed_simulator_repository" {
#  default = "https://github.com/amineelkouhen/crdb-authzed-load-test"
#}

variable "organization_name" {
  description = "Organization Name"
  default = "authzed_sandbox"
}

variable "cluster_license" {
  description = "Cluster License"
}

variable "preshared_key" {
  description = "API pre-shared key"
  default = "somerandomkeyhere"
}
