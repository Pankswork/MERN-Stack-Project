env                   = "dev"
aws_region            = "us-east-1"
vpc_cidr_block        = "10.16.0.0/16"
vpc_name              = "vpc"
igw_name              = "igw"
pub_subnet_count      = 3
pub_cidr_block        = ["10.16.0.0/20", "10.16.16.0/20", "10.16.32.0/20"]
pub_availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pub_sub_name          = "subnet-public"
pri_subnet_count      = 3
pri_cidr_block        = ["10.16.128.0/20", "10.16.144.0/20", "10.16.160.0/20"]
pri_availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pri_sub_name          = "subnet-private"
public_rt_name        = "public-route-table"
private_rt_name       = "private-route-table"
eip_name              = "elasticip-ngw"
ngw_name              = "ngw"
eks_sg                = "eks-sg"

# EKS
is_eks_cluster_enabled     = true
cluster_version            = "1.31"
cluster_name               = "eks-cluster"
endpoint_private_access    = true
endpoint_public_access     = false
ondemand_instance_types    = ["t3.small"]
spot_instance_types        = ["t3.small"]
desired_capacity_on_demand = "1"
min_capacity_on_demand     = "1"
max_capacity_on_demand     = "5"
desired_capacity_spot      = "1"
min_capacity_spot          = "1"
max_capacity_spot          = "10"

addons = [
  {
    name    = "vpc-cni"
    version = "v1.20.0-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.2-eksbuild.4"
  },
  {
    name    = "kube-proxy"
    version = "v1.31.0-eksbuild.2"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.46.0-eksbuild.1"
  }
]
