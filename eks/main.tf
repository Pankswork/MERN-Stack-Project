locals {
  org = "ap-medium"
  env = var.env
}

module "eks" {
  source = "../module"

  env                   = var.env
  cluster_name          = "${local.env}-${local.org}-${var.cluster_name}"
  cidr_block            = var.vpc_cidr_block
  vpc_name              = "${local.env}-${local.org}-${var.vpc_name}"
  igw_name              = "${local.env}-${local.org}-${var.igw_name}"
  pub_subnet_count      = var.pub_subnet_count
  pub_cidr_block        = var.pub_cidr_block
  pub_availability_zone = var.pub_availability_zone
  pub_sub_name          = "${local.env}-${local.org}-${var.pub_sub_name}"
  pri_subnet_count      = var.pri_subnet_count
  pri_cidr_block        = var.pri_cidr_block
  pri_availability_zone = var.pri_availability_zone
  pri_sub_name          = "${local.env}-${local.org}-${var.pri_sub_name}"
  public_rt_name        = "${local.env}-${local.org}-${var.public_rt_name}"
  private_rt_name       = "${local.env}-${local.org}-${var.private_rt_name}"
  eip_name              = "${local.env}-${local.org}-${var.eip_name}"
  ngw_name              = "${local.env}-${local.org}-${var.ngw_name}"
  eks_sg                = var.eks_sg

  is_eks_role_enabled           = true
  is_eks_nodegroup_role_enabled = true
  ondemand_instance_types       = var.ondemand_instance_types
  spot_instance_types           = var.spot_instance_types
  desired_capacity_on_demand    = var.desired_capacity_on_demand
  min_capacity_on_demand        = var.min_capacity_on_demand
  max_capacity_on_demand        = var.max_capacity_on_demand
  desired_capacity_spot         = var.desired_capacity_spot
  min_capacity_spot             = var.min_capacity_spot
  max_capacity_spot             = var.max_capacity_spot
  is_eks_cluster_enabled        = var.is_eks_cluster_enabled
  cluster_version               = var.cluster_version
  endpoint_private_access       = var.endpoint_private_access
  endpoint_public_access        = var.endpoint_public_access

  addons = var.addons
}
