
variable "region" {
  type = string
  default = "us-east-1"
}

variable "bastion_host_ami" {
  type = string
  default = "ami-0e322da50e0e90e21"
}

variable "key_pair_name" {
    type    = string
    default = "key1"
}

variable "vpcCidrBlock" {
  type = string
  default = "10.0.0.0/16"
}

# Subnets when the Nodes will be launched
variable "private_subnets" {
  type = list
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# 2 small Subnets dedicated for EKS network interfaces
# Nodes & Load balancers will be launched in seperate subnets.
variable "eks_interfaces_subnets" {
  type = list
  default = ["10.0.200.0/28", "10.0.201.0/28"]
}

# Subnets when the External Load balancers will be launched
variable "public_subnets" {
  type = list
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "ssh_ingress_cidrBlock" {
  type   = list
  default = ["0.0.0.0/0"]
}

variable "eks_cluster_name" {
  type = string
  default = "my_eks_cluster"
}

variable "instance_typ" {
  type    = string
  default = "t2.small"
}

variable "eks_cluster_version" {
  type = number
  default = 1.19
}
