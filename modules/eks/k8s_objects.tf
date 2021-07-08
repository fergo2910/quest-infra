# --------------------------------------------------------------------
# kubeconfig file
# --------------------------------------------------------------------

## generate a template for the kubeconfig file
data "template_file" "kubeconfig" {
  template = file("${path.module}/templates/kubeconfig.yaml.tpl")

  vars = {
    cluster_name     = var.cluster_name
    cluster_endpoint = aws_eks_cluster.masters.endpoint
    cluster_cert     = aws_eks_cluster.masters.certificate_authority[0].data
  }
}

## generate a local file from the rendered template, to be used by TF to deploy kube objects
resource "local_file" "kubeconfig" {
  count = var.generate_kube_config ? 1 : 0

  content  = data.template_file.kubeconfig.rendered
  filename = "./.kube/config_${var.cluster_name}"
}

# --------------------------------------------------------------------
# aws-auth ConfigMap
# --------------------------------------------------------------------

## generate base template for workers
data "template_file" "worker_role_arns" {
  template = file("${path.module}/templates/worker-role.tpl")

  vars = {
    workers_role_arn = aws_iam_role.k8s_workers_role.arn
  }
}

## generate templates mapping IAM users with cluster entities (users/groups)
data "template_file" "map_users" {
  count    = length(var.map_users)
  template = file("${path.module}/templates/aws-auth_map-users.yaml.tpl")

  vars = {
    user_arn = var.map_users[count.index]["user_arn"]
    username = var.map_users[count.index]["username"]
    group    = var.map_users[count.index]["group"]
  }
}

## generate templates mapping IAM roles with cluster entities (users/groups)
data "template_file" "map_roles" {
  count    = length(var.map_roles)
  template = file("${path.module}/templates/aws-auth_map-roles.yaml.tpl")

  vars = {
    role_arn = var.map_roles[count.index]["role_arn"]
    username = var.map_roles[count.index]["username"]
    group    = var.map_roles[count.index]["group"]
  }
}

## deploy the aws-auth ConfigMap
resource "kubernetes_config_map" "aws_auth_cm" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = join(
      "",
      data.template_file.map_roles.*.rendered,
      data.template_file.worker_role_arns.*.rendered,
    )
    mapUsers = join("", data.template_file.map_users.*.rendered)
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
  ]
}

# --------------------------------------------------------------------
# RBAC custom roles
# --------------------------------------------------------------------

## ClusterRole allowing read-only access to some kube objects
resource "kubernetes_cluster_role" "ro_cluster_role" {
  metadata {
    name = "read-only"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "pods/log", "pods/status", "configmaps", "services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}

## Bind the ClusterRole 'read-only' to a group named 'ReadOnlyGroup'
resource "kubernetes_cluster_role_binding" "ro_role_binding" {
  metadata {
    name = "read-only-global"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "read-only"
  }

  subject {
    kind      = "Group"
    name      = "ReadOnlyGroup"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_cluster_role.ro_cluster_role,
    kubernetes_config_map.aws_auth_cm,
  ]
}

## Bind the ClusterRole 'edit' to a group named 'PowerUserGroup'
resource "kubernetes_cluster_role_binding" "power_user" {
  metadata {
    name = "power-user-global"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  subject {
    kind      = "Group"
    name      = "PowerUserGroup"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}

# --------------------------------------------------------------------
# Namespace
# --------------------------------------------------------------------
resource "kubernetes_namespace" "environment" {
  count = var.create_environment_namespace ? 1 : 0

  metadata {
    name = var.environment
    labels = {
      name = var.environment
    }
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}

resource "kubernetes_namespace" "metrics" {
  count = var.create_metrics_namespace ? 1 : 0

  metadata {
    name = "metrics"
    labels = {
      name = "metrics"
    }
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}

resource "kubernetes_namespace" "additional" {
  for_each = toset(var.additional_namespaces)

  metadata {
    name = each.key
    labels = {
      name = each.key
    }
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}

# --------------------------------------------------------------------
# Secret for Docker Registry
# --------------------------------------------------------------------

## data source for decrypting the Docker Registry password (encrypted with KMS)
data "aws_kms_secrets" "docker_password" {
  count = var.docker_registry_secret ? 1 : 0

  secret {
    name    = "docker_password"
    payload = var.docker_encrypted_password
  }
}

resource "kubernetes_secret" "docker_registry_secret" {
  count = var.docker_registry_secret ? 1 : 0

  metadata {
    name      = var.docker_secret_name
    namespace = var.docker_secret_namespace
  }

  data = {
    ".dockercfg" = jsonencode(local.docker_config)
  }

  type = "kubernetes.io/dockercfg"

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}

#-----------------------
# CSI Driver
#-----------------------

# resource "null_resource" "csi-driver" {
#   provisioner "local-exec" {
#     command = "kubectl apply -f ${path.module}/kube_objects/csi-driver"
#     environment = {
#       KUBECONFIG  = local.kube_config
#       AWS_PROFILE = local.aws_profile
#     }
#   }
#   depends_on = [kubernetes_config_map.aws_auth_cm]
# }

#-----------------------
# EFS Storage Class
#-----------------------

# resource "kubernetes_storage_class" "efs-sc" {
#   metadata {
#     name = "efs-sc"
#   }
#   storage_provisioner = "efs.csi.aws.com"
#   depends_on          = [null_resource.csi-driver]
# }

# --------------------------------------------------------------------
# AWS VPC CNI Update
# --------------------------------------------------------------------
data "template_file" "aws_vpc_cni_manifest" {
  count = var.update_aws_vpc_cni ? 1 : 0

  template = local.aws_vpc_cni_manifest_template_file
  vars = {
    region   = data.aws_region.current.name
    irsa_arn = local.irsa_for_aws_vpc_cni ? aws_iam_role.aws_vpc_cni_role[0].arn : ""
  }

  depends_on = [
    aws_eks_cluster.masters
  ]

}

resource "kubectl_manifest" "aws_vpc_cni" {
  count     = var.update_aws_vpc_cni ? 1 : 0
  yaml_body = data.template_file.aws_vpc_cni_manifest[0].rendered
}

# --------------------------------------------------------------------
# Service accounts
# --------------------------------------------------------------------

resource "kubernetes_service_account" "additional_service_accounts" {
  for_each = var.additional_irsa

  metadata {
    name      = each.value.service_account_name
    namespace = each.value.service_account_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.additional_irsa[each.key].arn
    }
  }

  depends_on = [
    kubernetes_namespace.additional,
    kubernetes_namespace.environment
  ]

}


# ----------------------------------------------------------------------------------------------------------------
# pod disruption budget for adds on (in kube-system) to enable cluster autoscaler to delete those pods to downscale
# -----------------------------------------------------------------------------------------------------------------

resource "kubernetes_pod_disruption_budget" "pdb_dynamic" {
  for_each = var.addon_pod_disruption_budget_params

  metadata {
    name      = each.value.name
    namespace = "kube-system"
  }
  spec {
    max_unavailable = each.value.max_unavailable
    selector {
      match_labels = {
        (each.value.match_labels_key) = each.value.match_labels_value
      }
    }
  }
}

