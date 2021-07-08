# -------------------------------------------------------------
# Network variables
# -------------------------------------------------------------

variable "vpc_id" {
  description = "The ID of the VPC where we are deploying the EKS cluster"
}

variable "vpc_cidr" {
  description = "The CIDR range used in the VPC"
}

variable "public_subnets_ids" {
  description = "The IDs of at least two public subnets for the K8S control plane ENIs"
  type        = list(string)
}

variable "private_subnets_ids" {
  description = "The IDs of at least two private subnets to deploy the K8S workers in"
  type        = list(string)
}

# -------------------------------------------------------------
# EKS variables
# -------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the EKS cluster"
}

variable "amzn_eks_worker_ami_name" {
  description = "The name of the AMI to be used. Right now only supports Amazon Linux2 based EKS worker AMI"
}

variable "k8s_version" {
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used."
  default     = ""
}

variable "encrypted_boot_volume" {
  description = "If true, an encrypted EKS AMI will be created to support encrypted boot volumes"
}

variable "keypair_name" {
  description = "The name of an existing key pair to access the K8S workers via SSH"
  default     = ""
}

variable "boot_volume_type" {
  description = "The type of volume to allocate [gp2|io1]"
  default     = "gp2"
}

variable "iops" {
  description = "The amount of provisioned IOPS if volume type is io1"
  default     = 0
}

variable "boot_volume_size" {
  description = "The size of the root volume in GBs"
  default     = 200
}

variable "lb_target_group" {
  description = "The App LB target group ARN we want this AutoScaling Group belongs to"
  default     = ""
}

variable "map_users" {
  description = "A list of maps with the IAM users allowed to access EKS"
  type = list(object({
    user_arn = string
    username = string
    group    = string
  }))
  default = []
  # example:
  #
  #  map_users = [
  #    {
  #      user_arn = "arn:aws:iam::<aws-account>:user/JohnSmith"
  #      username = "john"
  #      group    = "system:masters" # cluster-admin
  #    },
  #    {
  #      user_arn = "arn:aws:iam::<aws-account>:user/PeterMiller"
  #      username = "peter"
  #      group    = "ReadOnlyGroup"  # custom role granting read-only permissions
  #    }
  #  ]
  #
}

variable "map_roles" {
  description = "A list of maps with the roles allowed to access EKS"
  type = list(object({
    role_arn = string
    username = string
    group    = string
  }))
  default = []
  # example:
  #
  #  map_roles = [
  #    {
  #      role_arn = "arn:aws:iam::<aws-account>:role/ReadOnly"
  #      username = "john"
  #      group    = "system:masters" # cluster-admin
  #    },
  #    {
  #      role_arn = "arn:aws:iam::<aws-account>:role/Admin"
  #      username = "peter"
  #      group    = "ReadOnlyGroup"  # custom role granting read-only permissions
  #    }
  #  ]
  #
}

variable "cluster_log_types" {
  description = "A list of the desired control plane logging to enable."
  type        = list(string)
  default     = []
  # Control plane log types available are: "api", "audit", "authenticator", "controllerManager", "scheduler".
}

variable "retention_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group."
  type        = number
  default     = 7
  # Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.
}

variable "docker_registry_secret" {
  description = "True if we want to create a secret object to pull images from Docker Hub"
  default     = false
}

variable "docker_secret_name" {
  description = "The name of the secret object to create in the k8s cluster"
  default     = "docker-registry"
}

variable "docker_server" {
  description = "Server location for Docker registry"
  default     = "https://index.docker.io/v1/"
}

variable "docker_username" {
  description = "Username for Docker registry authentication"
  default     = "docker_username"
}

variable "docker_encrypted_password" {
  description = "The KMS encrypted password (ciphertext) of the docker user"
  default     = ""
}

variable "docker_email" {
  description = "The email registered in the DockerHub account"
  default     = ""
}

variable "docker_secret_namespace" {
  description = "The namespace where to create the docker-registry secret"
  default     = "default"
}

variable "threatstack_key" {
  description = "The ThreatStack key to register the agent if running ThreatStack"
  default     = ""
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  default     = true
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  default     = false
}

# -------------------------------------------------------------
# Workers variables
# -------------------------------------------------------------


variable "ri_worker_configuration" {
  description = "A list of maps defining worker group configurations to be defined using AWS Launch Configurations. Meant to be used with RI."
  type        = map(string)
  default     = {}
  # Example:
  # ri_worker_configuration = {
  #   min_size         = 1
  #   desired_capacity = 2
  #   max_size         = 4
  #   instance_type    = "m5.xlarge"
  # }
}

variable "mixed_workers_configuration" {
  description = "A list of maps defining worker group configurations to be defined using AWS Launch Templates."
  type        = any
  default     = []

  # Example:
  # spot_workers_configuration = [{
  #   name                    = "spot"
  #   min_size                = 1
  #   desired_capacity        = 1
  #   max_size                = 4
  #   node_labels             = "spot=true"
  #   override_instance_types = ["r4.xlarge", "r4.2xlarge", "r5.xlarge", "r5.2xlarge", "t3.2xlarge", "t3a.2xlarge"]
  # }]
}

variable "worker_role_additional_policies" {
  description = "List of IAM policies ARNs to attach to the workers role"
  type        = list(string)
  default     = []
}

variable "asg_enabled_metrics" {
  description = "Listo of ASG CloudWatch metrics to be enabled"
  default = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
  ]
}

# -------------------------------------------------------------
# Security variables
# -------------------------------------------------------------

variable "allow_app_ports" {
  description = "A list of TCP ports to open in the K8S workers SG for instances/services in the VPC"
  type        = list(string)
  default     = ["22"]
}

# -------------------------------------------------------------
# Tagging
# -------------------------------------------------------------

variable "tags" {
  description = "A list of additional maps of tags to add to the autoscaling group if using K8S autoscaler"
  type        = map(string)
  default     = {}
}

variable "asg_tags" {
  description = "A list of maps of tags to add to the autoscaling group if using K8S autoscaler"
  type        = map(string)
  default     = {}
}

# -------------------------------------------------------------
# Environment
# -------------------------------------------------------------

variable "environment" {
  description = "The environment name"
  type        = string
}

# -------------------------------------------------------------
# Namespace
# -------------------------------------------------------------
variable "create_environment_namespace" {
  description = "Create a default namespace matching the environment name"
  type        = string
  default     = true
}

variable "create_metrics_namespace" {
  description = "Create a metrics namespace for the metrics server"
  type        = string
  default     = true
}

variable "additional_namespaces" {
  description = "A list of additional namespaces to create in cluster"
  type        = list(string)
  default     = []
}

variable "aws_profile" {
  description = "AWS CLI Profile to be used"
  default     = ""
}

variable "kube_config" {
  description = "Path to the kube config file to be used"
  default     = ""
}

variable "generate_kube_config" {
  description = "Whether to generate a kubeconfig file or not"
  type        = bool
  default     = false
}

# -------------------------------------------------------------
# Helm provider variables
# -------------------------------------------------------------

variable "disable_helm_plugins" {
  description = "True if we want to disable Helm plugins"
  default     = false
}

# -------------------------------------------------------------
# Helm deployment settings
# -------------------------------------------------------------

variable "chart_deployment_wait" {
  description = "If Terraform waits for all k8s objects to be in a ready state before marking the release as successful"
  default     = true
}

variable "deployment_timeout" {
  description = "Max time in seconds to wait for any individual kubernetes operation (if wait set to true)"
  default     = 600
}

# -------------------------------------------------------------
# Helm releases and repositories
# -------------------------------------------------------------

variable "helm_releases" {
  description = "A composite map containing a set of key/value pairs needed for deploying Helm charts to the EKS cluster"
  type = map(object({
    repository           = string
    chart_name           = string
    chart_version        = string
    release_name         = string
    namespace            = string
    values               = list(string)
    set_values           = map(string)
    set_sensitive_values = map(string)
  }))
  default = {}
  # example
  #
  # helm_releases = {
  #   "nginx-ingress" = {
  #     chart_name    = "stable/nginx-ingress"
  #     chart_version = ""                     # exact chart version to install, otherwise latest version will be installed
  #     release_name  = "nginx-ingress"
  #     namespace     = "kube-system"
  #     values        = []
  #   }
  # }
  #
}

# -------------------------------------------------------------
# Kubernetes Addons
# -------------------------------------------------------------

variable "addons" {
  description = "List of addons to install in the EKS cluster. Supported values: \"aws-alb-ingress-controller\", \"aws-node-termination-handler\", \"cluster-autoscaler\", \"external-dns\", \"metrics-server\", \"nginx-ingress-controller\"."
  type        = list(string)
  default = [
    "cluster-autoscaler",
    "metrics-server"
  ]
}

variable "addon_options" {
  description = "Map of addon-specific options to customize deployment"
  type        = any
  default     = {}
  # example
  #
  # addon_options = {
  #   "external-dns" = {
  #     "cross_account_access_role_arns": [
  #         "arn:aws:iam::111111111111:role/Route53ZoneManagementCrossAccountRole"
  #     ]
  #   }
  # }
}

variable "addon_helm_release_params" {
  description = "A composite map containing a set of key/value pairs overriding addon helm releases"
  type        = any
  default     = {}
  # example
  #
  # addon_helm_release_params = {
  #   "alb-ingress-controller" = {
  #     namespace     = "kube-system"
  #     values        = file("${path.cwd}/helm_values/alb-ingress-controller/${terraform.workspace}/values.yaml")
  #   },
  #   "external-dns" = {
  #     chart_version = "3.4.8"
  #     namespace     = "dns"
  #     values        = file()"${path.cwd}/helm_values/external-dns/${terraform.workspace}/values.yaml")
  #   }
  # }
  #
}

variable "addon_pod_disruption_budget_params" {
  description = "Map of addon-specific params to configure pod disruption budget to enable kube-system pods deletion with cluster-autoscaler"
  type        = map(any)
  default = {
    coredns = {
      name               = "coredns",
      max_unavailable    = 1,
      match_labels_key   = "eks.amazonaws.com/component",
      match_labels_value = "coredns"
    },
    external-dns = {
      name               = "external-dns",
      max_unavailable    = 0,
      match_labels_key   = "app.kubernetes.io/name",
      match_labels_value = "external-dns"
    },
    external-secrets = {
      name               = "external-secrets",
      max_unavailable    = 0,
      match_labels_key   = "eks.amazonaws.com/component",
      match_labels_value = "kubernetes-external-secrets"
    },
    metrics-server = {
      name               = "metrics-server",
      max_unavailable    = 0,
      match_labels_key   = "app",
      match_labels_value = "metrics-server"
    }
  }
}



# -------------------------------------------------------------
# IAM Roles for Service Accounts
# -------------------------------------------------------------
variable "enable_irsa" {
  description = "Enable/disable IAM roles for Service Accounts"
  type        = bool
  default     = true
}

variable "additional_irsa" {
  description = "Map of objects with definitions for additional IAM roles for service accounts (IRSA)"
  default     = {}
  type = map(object({
    policy_arns               = list(string)
    service_account_name      = string
    service_account_namespace = string
  }))
}

# -------------------------------------------------------------
# EKS/Kubernetes Misc Configuration
# -------------------------------------------------------------
variable "update_aws_vpc_cni" {
  description = "Set to true to update the AWS VPC CNI plugin to latest version (required to use IRSA for AWS VPC CNI pods)"

  type    = bool
  default = false
}

variable "additional_public_access_cidrs" {
  type = list(string)
}

variable "additional_private_access_cidrs" {
  type = list(string)
}
