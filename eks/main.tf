locals {
  org = "ap-medium"
  env = var.env
}

module "eks" {
  source = "../module"

  env                   = var.env
  cluster-name          = "${local.env}-${local.org}-${var.cluster_name}"
  cidr-block            = var.vpc_cidr_block
  vpc-name              = "${local.env}-${local.org}-${var.vpc_name}"
  igw-name              = "${local.env}-${local.org}-${var.igw_name}"

  pub-subnet-count      = var.pub_subnet_count
  pub-cidr-block        = var.pub_cidr_block
  pub-availability-zone = var.pub_availability_zone
  pub-sub-name          = "${local.env}-${local.org}-${var.pub_sub_name}"

  pri-subnet-count      = var.pri_subnet_count
  pri-cidr-block        = var.pri_cidr_block
  pri-availability-zone = var.pri_availability_zone
  pri-sub-name          = "${local.env}-${local.org}-${var.pri_sub_name}"

  public-rt-name        = "${local.env}-${local.org}-${var.public_rt_name}"
  private-rt-name       = "${local.env}-${local.org}-${var.private_rt_name}"
  eip-name              = "${local.env}-${local.org}-${var.eip_name}"
  ngw-name              = "${local.env}-${local.org}-${var.ngw_name}"

  eks-sg                = var.eks_sg

  # IAM role flags (module variables use underscores)
  is_eks_role_enabled           = true
  is_eks_nodegroup_role_enabled = true

  # Node group instance types (module variables use underscores)
  ondemand_instance_types       = var.ondemand_instance_types
  spot_instance_types           = var.spot_instance_types

  # Node group capacity settings (module variables use underscores)
  desired_capacity_on_demand    = var.desired_capacity_on_demand
  min_capacity_on_demand        = var.min_capacity_on_demand
  max_capacity_on_demand        = var.max_capacity_on_demand

  desired_capacity_spot         = var.desired_capacity_spot
  min_capacity_spot             = var.min_capacity_spot
  max_capacity_spot             = var.max_capacity_spot

  is-eks-cluster-enabled        = var.is_eks_cluster_enabled
  cluster-version               = var.cluster_version
  endpoint-private-access       = var.endpoint_private_access
  endpoint-public-access        = var.endpoint_public_access

  addons = var.addons
}

