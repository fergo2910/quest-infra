# --------------------------------------------------------------------
# Terraform data sources
# --------------------------------------------------------------------

## Get an Amazon Linux2 image optimized for EKS K8S workers using the given name
data "aws_ami" "amazon_eks_workers" {
  filter {
    name   = "name"
    values = [var.amzn_eks_worker_ami_name]
  }

  owners = ["602401143452", "self"] # Owned by Amazon and current account.
}

# -------------------------------------------------------------
# locals expressions to compute AMI ID and userdata script
# -------------------------------------------------------------

locals {
  ami_id = var.encrypted_boot_volume ? join("", aws_ami_copy.encrypted_eks_ami.*.id) : data.aws_ami.amazon_eks_workers.image_id

  worker_userdata = {
    ## cloud-init script to bootstrap Amazon Linux2 EKS-optimized image
    ## to configure kubeconfig for kubelet
    amazon = <<USERDATA
    #!/bin/bash
    set -o xtrace
    %s 
    /etc/eks/bootstrap.sh --kubelet-extra-args '--node-labels=%s --register-with-taints=%s %s' ${var.cluster_name}
USERDATA
  }

  # Docker configuration

  docker_config = {
    (var.docker_server) = {
      email    = var.docker_email
      username = var.docker_username
      password = var.docker_registry_secret && var.docker_encrypted_password != "" ? data.aws_kms_secrets.docker_password.0.plaintext["docker_password"] : ""
    }
  }
}

locals {
  aws_default_profile = "rearc-${terraform.workspace}"
  aws_profile         = var.aws_profile != "" ? var.aws_profile : local.aws_default_profile

  default_kube_config = "${path.module}/.kube/config_rearc-${terraform.workspace}"
  kube_config         = var.kube_config != "" ? var.kube_config : local.default_kube_config
}

# -------------------------------------------------------------
# Kubernetes addons and plugins
# -------------------------------------------------------------

locals {
  addon_default_helm_releases = {
    external-dns = {
      repository           = "https://charts.bitnami.com/bitnami"
      chart_name           = "external-dns"
      chart_version        = "2.10.3" # exact chart version to install, otherwise latest version will be installed
      release_name         = "external-dns"
      namespace            = "kube-system"
      values_template_file = file("${path.module}/helm_values/external-dns/values.yaml.tpl")
      values               = []
      set_values           = { "aws.zoneType" : "public" }
      set_sensitive_values = {}
      force_update         = false
    },
    external-dns-private = {
      repository           = "https://charts.bitnami.com/bitnami"
      chart_name           = "external-dns"
      chart_version        = "2.10.3" # exact chart version to install, otherwise latest version will be installed
      release_name         = "external-dns-private"
      namespace            = "kube-system"
      values_template_file = file("${path.module}/helm_values/external-dns/values.yaml.tpl")
      values               = []
      set_values           = { "aws.zoneType" : "private" }
      set_sensitive_values = {}
      force_update         = false
    },
    metrics-server = {
      repository           = "https://charts.helm.sh/stable"
      chart_name           = "metrics-server"
      chart_version        = "2.11.2" # exact chart version to install, otherwise latest version will be installed
      release_name         = "metrics-server"
      namespace            = "kube-system"
      values_template_file = file("${path.module}/helm_values/metrics-server/values.yaml.tpl")
      values               = []
      set_values           = {}
      set_sensitive_values = {}
      force_update         = false
    },
    cluster-autoscaler = {
      repository           = "https://charts.helm.sh/stable"
      chart_name           = "cluster-autoscaler"
      chart_version        = "8.0.0"
      release_name         = "cluster-autoscaler"
      namespace            = "kube-system"
      values_template_file = file("${path.module}/helm_values/cluster-autoscaler/values.yaml.tpl")
      values               = []
      set_values           = {}
      set_sensitive_values = {}
      force_update         = false
    },
    aws-alb-ingress-controller = {
      repository           = "https://charts.helm.sh/incubator"
      chart_name           = "aws-alb-ingress-controller"
      chart_version        = "1.0.2"
      release_name         = "alb-ingress-controller"
      namespace            = "ingress"
      values_template_file = file("${path.module}/helm_values/aws-alb-ingress-controller/values.yaml.tpl")
      values               = []
      set_values           = {}
      set_sensitive_values = {}
      force_update         = false
    },
    aws-node-termination-handler = {
      repository           = "https://aws.github.io/eks-charts"
      chart_name           = "aws-node-termination-handler"
      chart_version        = "0.7.5"
      release_name         = "aws-node-termination-handler"
      namespace            = "kube-system"
      values_template_file = file("${path.module}/helm_values/aws-node-termination-handler/values.yaml.tpl")
      values               = []
      set_values           = {}
      set_sensitive_values = {}
      force_update         = false
    },
    kubernetes-external-secrets = {
      repository           = "https://external-secrets.github.io/kubernetes-external-secrets"
      chart_name           = "kubernetes-external-secrets"
      chart_version        = "8.1.2"
      release_name         = "kubernetes-external-secrets"
      namespace            = "kube-system"
      values_template_file = file("${path.module}/helm_values/kubernetes-external-secrets/values.yaml.tpl")
      values               = []
      set_values           = {}
      set_sensitive_values = {}
      force_update         = false
    },
  }

  addon_default_options = {
    "external-dns" = {
      "cross_account_access_role_arns" = []
    },
    "external-dns-private" = {
      "cross_account_access_role_arns" = []
    }
  }

  addon_config = {
    aws-alb-ingress-controller = {
      enabled = contains(var.addons, "aws-alb-ingress-controller"),
      options = {}
      helm_release = merge(
        local.addon_default_helm_releases["aws-alb-ingress-controller"],
        lookup(var.addon_helm_release_params, "aws-alb-ingress-controller", {})
      )
    },
    aws-node-termination-handler = {
      enabled = contains(var.addons, "aws-node-termination-handler"),
      options = {}
      helm_release = merge(
        local.addon_default_helm_releases["aws-node-termination-handler"],
        lookup(var.addon_helm_release_params, "aws-node-termination-handler", {})
      )
    },
    cluster-autoscaler = {
      enabled = contains(var.addons, "cluster-autoscaler"),
      options = {}
      helm_release = merge(
        local.addon_default_helm_releases["cluster-autoscaler"],
        lookup(var.addon_helm_release_params, "cluster-autoscaler", {})
      )
    },
    external-dns = {
      enabled = contains(var.addons, "external-dns"),
      options = merge(
        local.addon_default_options["external-dns"],
        lookup(var.addon_options, "external-dns", {})
      )
      helm_release = merge(
        local.addon_default_helm_releases["external-dns"],
        lookup(var.addon_helm_release_params, "external-dns", {})
      )
    },
    external-dns-private = {
      enabled = contains(var.addons, "external-dns-private"),
      options = merge(
        local.addon_default_options["external-dns-private"],
        lookup(var.addon_options, "external-dns-private", {})
      )
      helm_release = merge(
        local.addon_default_helm_releases["external-dns-private"],
        lookup(var.addon_helm_release_params, "external-dns-private", {})
      )
    },
    metrics-server = {
      enabled = contains(var.addons, "metrics-server"),
      options = {}
      helm_release = merge(
        local.addon_default_helm_releases["metrics-server"],
        lookup(var.addon_helm_release_params, "metrics-server", {})
      )
    },
    kubernetes-external-secrets = {
      enabled = contains(var.addons, "kubernetes-external-secrets"),
      options = {}
      helm_release = merge(
        local.addon_default_helm_releases["kubernetes-external-secrets"],
        lookup(var.addon_helm_release_params, "kubernetes-external-secrets", {})
      )
    },
  }

  addon_enabled_helm_releases = { for k, v in local.addon_config : k => v.helm_release if v.enabled }

  addon_enabled_helm_release_blended_values = {
    for k, v in data.template_file.addon_release_values :
    k => concat(
      [v.rendered],
      lookup(
        local.addon_enabled_helm_releases[k],
        "values",
        []
      )
    )
  }

  addon_create_roles = {
    external-dns                 = local.addon_config["external-dns"].enabled && var.enable_irsa,
    metrics-server               = false
    cluster-autoscaler           = local.addon_config["cluster-autoscaler"].enabled && var.enable_irsa,
    ingress-controller           = local.addon_config["aws-alb-ingress-controller"].enabled && var.enable_irsa,
    aws-node-termination-handler = local.addon_config["aws-node-termination-handler"].enabled && var.enable_irsa,
    kubernetes-external-secrets  = local.addon_config["kubernetes-external-secrets"].enabled && var.enable_irsa,
  }

  addon_create_policies = {
    external-dns                 = local.addon_config["external-dns"].enabled,
    external-dns_recordsets      = local.addon_config["external-dns"].enabled
    external-dns_cross-account   = local.addon_config["external-dns"].enabled && length(local.addon_config["external-dns"].options.cross_account_access_role_arns) > 0
    metrics-server               = false
    cluster-autoscaler           = local.addon_config["cluster-autoscaler"].enabled
    ingress-controller           = local.addon_config["aws-alb-ingress-controller"].enabled
    aws-node-termination-handler = local.addon_config["aws-node-termination-handler"].enabled
    kubernetes-external-secrets  = local.addon_config["kubernetes-external-secrets"].enabled
  }

  addon_attach_policies_to_irsa = {
    external-dns                 = local.addon_create_policies["external-dns"] && var.enable_irsa,
    external-dns_cross-account   = local.addon_create_policies["external-dns_cross-account"] && var.enable_irsa
    metrics-server               = local.addon_create_policies["metrics-server"] && var.enable_irsa
    cluster-autoscaler           = local.addon_create_policies["cluster-autoscaler"] && var.enable_irsa,
    aws-node-termination-handler = local.addon_create_policies["aws-node-termination-handler"] && var.enable_irsa,
    ingress-controller           = local.addon_create_policies["ingress-controller"] && var.enable_irsa
    ingress-controller-upgrade   = var.enable_irsa
    kubernetes-external-secrets  = local.addon_create_policies["kubernetes-external-secrets"] && var.enable_irsa
  }

  addon_attach_policies_to_worker_role = {
    external-dns                 = local.addon_create_policies["external-dns"] && !var.enable_irsa,
    external-dns_cross-account   = local.addon_create_policies["external-dns_cross-account"] && !var.enable_irsa
    metrics-server               = local.addon_create_policies["metrics-server"] && !var.enable_irsa
    cluster-autoscaler           = local.addon_create_policies["cluster-autoscaler"] && !var.enable_irsa,
    aws-node-termination-handler = local.addon_create_policies["aws-node-termination-handler"] && !var.enable_irsa,
    ingress-controller           = local.addon_create_policies["ingress-controller"] && !var.enable_irsa
    ingress-controller-upgrade   = !var.enable_irsa
    kubernetes-external-secrets  = local.addon_create_policies["kubernetes-external-secrets"] && !var.enable_irsa
  }

  addon_role_arns = {
    external-dns                 = var.enable_irsa && local.addon_config["external-dns"].enabled ? aws_iam_role.external_dns_role[0].arn : ""
    external-dns-private         = var.enable_irsa && local.addon_config["external-dns-private"].enabled ? aws_iam_role.external_dns_role[0].arn : ""
    metrics-server               = ""
    cluster-autoscaler           = var.enable_irsa && local.addon_config["cluster-autoscaler"].enabled ? aws_iam_role.cluster_autoscaler_role[0].arn : ""
    aws-alb-ingress-controller   = var.enable_irsa && local.addon_config["aws-alb-ingress-controller"].enabled ? aws_iam_role.ingress_controller_role[0].arn : ""
    aws-node-termination-handler = ""
    kubernetes-external-secrets  = var.enable_irsa && local.addon_config["kubernetes-external-secrets"].enabled ? aws_iam_role.kubernetes_external_secrets_role[0].arn : ""
  }

  addon_fq_service_account_names = {
    aws-alb-ingress-controller   = "system:serviceaccount:${local.addon_config["aws-alb-ingress-controller"].helm_release.namespace}:${local.addon_config["aws-alb-ingress-controller"].helm_release.release_name}"
    external-dns                 = "system:serviceaccount:${local.addon_config["external-dns"].helm_release.namespace}:${local.addon_config["external-dns"].helm_release.release_name}",
    external-dns-private         = "system:serviceaccount:${local.addon_config["external-dns-private"].helm_release.namespace}:${local.addon_config["external-dns-private"].helm_release.release_name}",
    metrics-server               = "system:serviceaccount:${local.addon_config["metrics-server"].helm_release.namespace}:${local.addon_config["metrics-server"].helm_release.release_name}"
    cluster-autoscaler           = "system:serviceaccount:${local.addon_config["cluster-autoscaler"].helm_release.namespace}:${local.addon_config["cluster-autoscaler"].helm_release.release_name}",
    aws-node-termination-handler = "system:serviceaccount:${local.addon_config["aws-node-termination-handler"].helm_release.namespace}:${local.addon_config["aws-node-termination-handler"].helm_release.release_name}",
    kubernetes-external-secrets  = "system:serviceaccount:${local.addon_config["kubernetes-external-secrets"].helm_release.namespace}:${local.addon_config["kubernetes-external-secrets"].helm_release.release_name}",
  }

  cluster_autoscaler_enabled         = local.addon_config["cluster-autoscaler"].enabled
  irsa_for_aws_vpc_cni               = var.enable_irsa && var.update_aws_vpc_cni
  aws_vpc_cni_manifest_template_file = file("${path.module}/manifests/aws-vpc-cni.yaml.tpl")
}

# -------------------------------------------------------------
# Additional IRSA
# -------------------------------------------------------------
locals {
  irsa_create_additional_roles = length(var.additional_irsa) > 0
  irsa_additional_fq_service_account_names = {
    for k, v in var.additional_irsa : k => "system:serviceaccount:${v.service_account_namespace}:${v.service_account_name}"
  }

  irsa_additional_policy_attachments = merge({}, [
    for irsa_k, irsa_v in var.additional_irsa : {
      for p_arn in irsa_v.policy_arns : md5("${irsa_k}-${p_arn}") => {
        "role"       = aws_iam_role.additional_irsa[irsa_k].name
        "policy_arn" = p_arn
      }
    }
  ]...)
}