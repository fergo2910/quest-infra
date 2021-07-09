# --------------------------------------------------------------------
# K8S Container Insights
# --------------------------------------------------------------------

#locals {
#  namespace      = lookup(var.helm, "namespace", "amazon-cloudwatch")
#  serviceaccount = lookup(var.helm, "serviceaccount", "aws-container-insights")
#}

data "aws_partition" "current" {}

#module "irsa" {
#  count = local.addon_create_policies["aws-container-insights"] ? 1 : 0
#     
#  source         = "../iam-role-for-serviceaccount"
#  count          = var.enabled ? 1 : 0
#  name           = join("-", ["irsa", local.name])
#  namespace      = local.namespace
#  serviceaccount = local.serviceaccount
#  oidc_url       = var.oidc.url
#  oidc_arn       = var.oidc.arn
#  policy_arns    = [aws_iam_policy.containerinsights.0.arn]
#  tags           = var.tags
#}
data "aws_iam_policy_document" "aws_container_insights_trust_policy" {
  count = local.addon_create_policies["aws-container-insights"] ? 1 : 0

  statement {
    sid    = "EKSContainerInsightsTrustPolicyStatement"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.oidc[0].url}:sub"

      values = compact([
        local.addon_config["aws-container-insights"].enabled ? (
          local.addon_fq_service_account_names["aws-container-insights"]
        ) : ""
      ])
    }
  }
}

resource "aws_iam_role" "aws_container_insights_role" {
  count = local.addon_create_roles["aws-container-insights"] ? 1 : 0

  name               = "${var.environment}-EksContainerInsightsRole"
  assume_role_policy = data.aws_iam_policy_document.aws_container_insights_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "aws_container_insights_role_policy" {
  count = local.addon_create_policies["aws-container-insights"] ? 1 : 0

  policy_arn = aws_iam_policy.aws_container_insights_policy[0].arn
  role       = aws_iam_role.aws_container_insights_role[0].name
}

resource "aws_iam_policy" "aws_container_insights_policy" {
  count = local.addon_create_policies["aws-container-insights"] ? 1 : 0

  name        = "${var.environment}-EksContainerInsights"
  description = format("Allow cloudwatch-agent to manage AWS CloudWatch logs for ContainerInsights")
  policy      = data.aws_iam_policy_document.aws_container_insights_policy[0].json

}


data "aws_iam_policy_document" "aws_container_insights_policy" {
  count = local.addon_create_policies["aws-container-insights"] ? 1 : 0

  statement {
    sid    = "EKSLogsContainerInsightsPolicyStatement"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }
  statement {
    sid    = "EKSEC2ContainerInsightsPolicyStatement"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes"
    ]

    resources = [
      "*"
    ]
  }
}

#resource "helm_release" "containerinsights" {
#  count = local.addon_create_policies["aws-container-insights"] ? 1 : 0
#  
#  name             = lookup(var.helm, "name", "eks-cw")
#  chart            = lookup(var.helm, "chart", "containerinsights")
#  version          = lookup(var.helm, "version", null)
#  repository       = lookup(var.helm, "repository", join("/", [path.module, "charts"]))
#  namespace        = local.namespace
#  create_namespace = true
#  cleanup_on_fail  = lookup(var.helm, "cleanup_on_fail", true)
#
#  dynamic "set" {
#    for_each = {
#      "cluster.name"                                              = var.cluster_name
#      "cluster.region"                                            = data.aws_region.current.0.name
#      "serviceAccount.name"                                       = local.serviceaccount
#      "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.irsa[0].arn[0]
#    }
#    content {
#      name  = set.key
#      value = set.value
#    }
#  }
#}