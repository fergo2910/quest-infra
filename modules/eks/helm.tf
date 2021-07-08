# --------------------------------------------------------------------
# Helm Charts to deploy
# --------------------------------------------------------------------

data "template_file" "addon_release_values" {
  for_each = local.addon_enabled_helm_releases

  template = each.value.values_template_file
  vars = {
    fullname_override = each.value.release_name
    irsa_arn          = local.addon_role_arns[each.key]
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_iam_role.aws_vpc_cni_role,
    aws_iam_role.ingress_controller_role,
    aws_iam_role.aws_load_balancer_controller_role,
    aws_iam_role.cluster_autoscaler_role,
    aws_iam_role.external_dns_role,
    aws_iam_role.kubernetes_external_secrets_role,
    aws_iam_role.aws_container_insights_role
  ]
}

resource "helm_release" "addon_release" {
  for_each = {
    for k, v in data.template_file.addon_release_values : k => local.addon_enabled_helm_releases[k]
  }

  repository       = each.value.repository
  chart            = each.value.chart_name
  name             = each.value.release_name
  version          = each.value.chart_version
  namespace        = each.value.namespace
  create_namespace = true
  values           = local.addon_enabled_helm_release_blended_values[each.key]
  force_update     = each.value.force_update

  dynamic "set" {
    for_each = each.value.set_values

    content {
      type  = "auto"
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = each.value.set_sensitive_values

    content {
      type  = "auto"
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }

  wait    = var.chart_deployment_wait
  timeout = var.deployment_timeout

  depends_on = [
    aws_autoscaling_group.mixed-worker-nodes
  ]
}

resource "helm_release" "additional_release" {
  for_each = var.helm_releases

  repository       = each.value.repository
  chart            = each.value.chart_name
  name             = each.value.release_name
  version          = each.value.chart_version
  namespace        = each.value.namespace
  create_namespace = true
  values           = each.value.values != [] ? [for path in each.value.values : file(path)] : []

  dynamic "set" {
    for_each = each.value.set_values

    content {
      type  = "auto"
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = each.value.set_sensitive_values

    content {
      type  = "auto"
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }

  wait    = var.chart_deployment_wait
  timeout = var.deployment_timeout

  depends_on = [
    aws_autoscaling_group.mixed-worker-nodes
  ]
}
