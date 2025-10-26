# AWS & Environment
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

# VPC
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "igw_name" {
  description = "Internet Gateway name"
  type        = string
}

# Public Subnets
variable "pub_subnet_count" {
  description = "Number of public subnets"
  type        = number
}

variable "pub_cidr_block" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "pub_availability_zone" {
  description = "Availability zones for public subnets"
  type        = list(string)
}

variable "pub_sub_name" {
  description = "Public subnet name prefix"
  type        = string
}

# Private Subnets
variable "pri_subnet_count" {
  description = "Number of private subnets"
  type        = number
}

variable "pri_cidr_block" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "pri_availability_zone" {
  description = "Availability zones for private subnets"
  type        = list(string)
}

variable "pri_sub_name" {
  description = "Private subnet name prefix"
  type        = string
}

# Route Tables & Gateways
variable "public_rt_name" {
  description = "Public route table name"
  type        = string
}

variable "private_rt_name" {
  description = "Private route table name"
  type        = string
}

variable "eip_name" {
  description = "Elastic IP name"
  type        = string
}

variable "ngw_name" {
  description = "NAT Gateway name"
  type        = string
}

variable "eks_sg" {
  description = "EKS Security Group ID"
  type        = string
}

# EKS Cluster
variable "is_eks_cluster_enabled" {
  description = "Enable EKS cluster creation"
  type        = bool
  default     = true
}

variable "cluster_version" {
  description = "EKS cluster Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "endpoint_private_access" {
  description = "Enable private access for EKS endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access for EKS endpoint"
  type        = bool
  default     = true
}

# Node Group
variable "ondemand_instance_types" {
  description = "List of On-Demand instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "spot_instance_types" {
  description = "List of Spot instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "desired_capacity_on_demand" {
  description = "Desired capacity for On-Demand nodes"
  type        = number
}

variable "min_capacity_on_demand" {
  description = "Minimum capacity for On-Demand nodes"
  type        = number
}

variable "max_capacity_on_demand" {
  description = "Maximum capacity for On-Demand nodes"
  type        = number
}

variable "desired_capacity_spot" {
  description = "Desired capacity for Spot nodes"
  type        = number
}

variable "min_capacity_spot" {
  description = "Minimum capacity for Spot nodes"
  type        = number
}

variable "max_capacity_spot" {
  description = "Maximum capacity for Spot nodes"
  type        = number
}

# EKS Add-ons
variable "addons" {
  description = "List of EKS add-ons with name and version"
  type = list(object({
    name    = string
    version = string
  }))
  default = []
}
