module "vpc" {
  source = "./modules/vpc"

  environment = terraform.workspace

  # Network settings
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.database_subnet_cidrs

  enable_nat_gw      = true
  single_nat_gw      = var.single_nat_gw
  enable_dns_support = true
  map_to_public_ip   = true

  # Security settings: custom ACL rules for public subnets
  allow_inbound_traffic_public_subnet  = var.allow_inbound_traffic
  allow_inbound_traffic_private_subnet = var.allow_inbound_traffic

  # Tagging
  tags = {
    environment = terraform.workspace
    App         = "rearc-quest-${terraform.workspace}"
  }

  # Tags needed for EKS to identify public and private subnets
  eks_network_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  eks_private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  eks_public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

}

module "iam" {
  source = "./modules/iam"
  region = var.region
}

module "ecr_repo" {
  source = "./modules/ecr"

  create_repos          = true
  repos                 = local.repos
  resource_based_policy = false
}

module "eks" {
  source = "./modules/eks"

  environment                     = terraform.workspace
  cluster_name                    = local.cluster_name
  vpc_id                          = module.vpc.vpc_id
  vpc_cidr                        = module.vpc.vpc_cidr
  public_subnets_ids              = module.vpc.public_subnet_ids
  private_subnets_ids             = module.vpc.private_subnet_ids
  endpoint_private_access         = false
  endpoint_public_access          = true
  additional_public_access_cidrs  = local.eks_whitelist_ip
  additional_private_access_cidrs = var.private_subnet_cidrs
  cluster_log_types               = local.cluster_log_types[terraform.workspace]
  k8s_version                     = local.cluster_version[terraform.workspace]
  amzn_eks_worker_ami_name        = local.eks_worker_ami_name[terraform.workspace]
  encrypted_boot_volume           = local.eks_worker_encrypted_boot_volume[terraform.workspace]
  mixed_workers_configuration     = local.mixed_workers_configuration
  ### circleci user
  map_users = local.map_users
  map_roles = [
    {
      role_arn = module.iam.rbac_admin
      username = "admin:{{SessionName}}"
      group    = "system:masters" # cluster-admin
    },
    {
      role_arn = module.iam.rbac_readonly
      username = "ReadOnly:{{SessionName}}"
      group    = "ReadOnlyGroup" # read-only
    },
    {
      role_arn = module.iam.rbac_poweruser
      username = "PowerUser:{{SessionName}}"
      group    = local.developers_cluster_role
    },
  ]
  # EKS Namespaces
  additional_namespaces = local.k8s_additional_namespaces[terraform.workspace]
  # Kubernetes Addons
  addons                    = local.k8s_addons
  addon_helm_release_params = local.k8s_addon_helm_release_params
  # Install Additional Helm Charts
  helm_releases      = local.k8s_helm_releases
  enable_irsa        = local.cluster_enable_irsa[terraform.workspace]
  update_aws_vpc_cni = true
  additional_irsa    = local.k8s_application_irsa_config
  tags               = merge(local.tags, local.tags_kubernetes)
}