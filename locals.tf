data "aws_region" "current" {}

locals {

  # --------------------
  # Account IDs
  # --------------------

  account_id = {
    prod = "750208817861",
  }

  # --------------------
  # EKS Variables
  # --------------------
  cluster_name = "${var.cluster_name}-${terraform.workspace}"
  cluster_version = {
    dev  = "1.19"
    prod = "1.19"
  }
  #TBD
  cluster_log_types = {
    dev  = []
    prod = []
  }
  cluster_enable_irsa = {
    dev  = true
    prod = true
  }
  eks_worker_ami_name = {
    dev  = "amazon-eks-node-1.19-v20210322"
    prod = "amazon-eks-node-1.19-v20210322"
  }
  eks_worker_encrypted_boot_volume = {
    dev  = false
    prod = true
  }
  mixed_workers_configuration = try(concat(
    [local.spot_workers_configuration[terraform.workspace]],
    [local.stable_workers_configuration[terraform.workspace]]
    ),
    []
  )
  spot_workers_configuration = {
    dev = {
      name                    = "spot"
      min_size                = 0
      desired_capacity        = 0
      max_size                = 0
      override_instance_types = local.spot_mixed_instance_types
      node_labels             = "node-type=spot"
    },
    prod = {
      name                    = "spot"
      min_size                = 0
      desired_capacity        = 0
      max_size                = 0
      override_instance_types = local.spot_mixed_instance_types
      node_labels             = "node-type=spot"
    },
  }
  stable_workers_configuration = {
    dev = {
      name                                     = "stable"
      min_size                                 = 1
      desired_capacity                         = 2
      max_size                                 = 6
      override_instance_types                  = ["t2.micro"] # Using spot we need to extend our options
      node_labels                              = "node-type=stable"
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 50
    },
    prod = {
      name                                     = "stable"
      min_size                                 = 3
      desired_capacity                         = 3
      max_size                                 = 10
      override_instance_types                  = ["t2.micro"] # Using spot we need to extend our options
      node_labels                              = "node-type=stable"
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 50
    },
  }
  spot_mixed_instance_types = ["t2.micro"]

  # --------------------
  # EKS/Kubernetes Configuration
  # --------------------
  eks_whitelist_ip = var.additional_public_access_cidrs == [] ? module.vpc.elastic_ips_cidrs : try(concat(module.vpc.elastic_ips_cidrs, var.additional_public_access_cidrs))
  developers_cluster_role_map = {
    dev  = "system:masters"
    prod = "system:masters"
  }
  developers_cluster_role = try(local.developers_cluster_role_map[terraform.workspace], "")
  pipeline_cluster_role_map = {
    dev  = "PowerUserGroup"
    prod = "system:masters"
  }
  pipeline_cluster_role = try(local.pipeline_cluster_role_map[terraform.workspace], "")
  # EKS Namespaces
  k8s_application_namespace = "rearc"
  k8s_additional_namespaces = {
    dev  = [local.k8s_application_namespace]
    prod = [local.k8s_application_namespace]
  }
  k8s_helm_releases = {
  }
  k8s_application_irsa_config = {
    rearc-app = {
      policy_arns               = []
      service_account_name      = "rearc-app"
      service_account_namespace = local.k8s_application_namespace
    },
  }
  k8s_addons = [
    "aws-alb-ingress-controller",
    "kubernetes-external-secrets",
    "cluster-autoscaler",
    "external-dns",
    "metrics-server",
  ]
  k8s_addon_helm_release_params = {
    aws-alb-ingress-controller = {
      values = [
        file("${path.cwd}/helm_values/alb-ingress-controller/values.yaml"),
        file("${path.cwd}/helm_values/alb-ingress-controller/${terraform.workspace}/values.yaml")
      ]
      set_values = {
        "awsVpcID" : module.vpc.vpc_id,
        "awsRegion" : data.aws_region.current.name
        "clusterName" : local.cluster_name
      }
    },
    kubernetes-external-secrets = {
      set_values = {
        "env.AWS_DEFAULT_REGION" : data.aws_region.current.name,
        "env.AWS_REGION" : data.aws_region.current.name
      }
    },
    external-dns = {
      set_values = {
        "domainFilters[0]" : module.internal_domain.domain_name
        "awsRegion" : data.aws_region.current.name
      }
    },
    cluster-autoscaler = {
      values = [
        file("${path.cwd}/helm_values/cluster-autoscaler/values.yaml"),
        file("${path.cwd}/helm_values/cluster-autoscaler/${terraform.workspace}/values.yaml")
      ]
      set_values = {
        "awsRegion" : data.aws_region.current.name,
        "autoDiscovery.clusterName" : local.cluster_name
      }
    },
  }

  # --------------------
  # Tagging
  # --------------------

  tags_kubernetes = {
    service = "kubernetes"
    version = local.cluster_version[terraform.workspace]
  }

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }

  map_default_users = [
    {
      user_arn = module.iam.circle-ci-user-arn
      username = "rearc:${module.iam.circle-ci-user-name}"
      group    = "system:masters" # cluster-admin
    }
  ]
  map_users = local.map_default_users
}