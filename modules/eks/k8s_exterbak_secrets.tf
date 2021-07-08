# --------------------------------------------------------------------
# K8S External Secrets
# --------------------------------------------------------------------

data "aws_iam_policy_document" "external_secrets_trust_policy" {
  count = local.addon_create_roles["kubernetes-external-secrets"] ? 1 : 0

  statement {
    sid    = "EKSExternalSecretsTrustPolicyStatement"
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
        local.addon_config["kubernetes-external-secrets"].enabled ? (
          local.addon_fq_service_account_names["kubernetes-external-secrets"]
        ) : "",
        local.addon_config["kubernetes-external-secrets"].enabled ? (
          local.addon_fq_service_account_names["kubernetes-external-secrets"]
        ) : ""
      ])
    }
  }
}

resource "aws_iam_role" "kubernetes_external_secrets_role" {
  count = local.addon_create_roles["kubernetes-external-secrets"] ? 1 : 0

  name               = "${var.environment}-EksExternalSecretsRole"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "external_secrets_role_policy" {
  count = local.addon_attach_policies_to_irsa["kubernetes-external-secrets"] ? 1 : 0

  policy_arn = aws_iam_policy.external_secrets_policy[0].arn
  role       = aws_iam_role.kubernetes_external_secrets_role[0].name
}

resource "aws_iam_policy" "external_secrets_policy" {
  count = local.addon_create_policies["kubernetes-external-secrets"] ? 1 : 0

  name        = "${var.environment}-KubernetesExternalSecrets"
  description = "Allows K8S cluster retrieve ssm parameters"
  policy      = data.aws_iam_policy_document.external_secrets_policy[0].json
}

data "aws_iam_policy_document" "external_secrets_policy" {
  count = local.addon_create_policies["kubernetes-external-secrets"] ? 1 : 0

  statement {
    sid    = "SSMAccessForK8s"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${upper(var.environment)}/*",
    ]
  }
}

## ClusterRole allowing access to externalsecrets
resource "kubernetes_cluster_role" "external_secrets" {
  metadata {
    name = "external-secrets"
    labels = {
      "rbac.authorization.k8s.io/aggregate-to-edit" = true
    }
  }

  rule {
    api_groups = ["kubernetes-client.io"]
    resources  = ["externalsecrets"]
    verbs      = ["get", "list", "delete", "create", "update", "patch"]
  }

  depends_on = [
    aws_eks_cluster.masters,
    aws_autoscaling_group.mixed-worker-nodes,
    kubernetes_config_map.aws_auth_cm,
  ]
}