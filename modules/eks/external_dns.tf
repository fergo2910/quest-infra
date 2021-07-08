# --------------------------------------------------------------------
# K8S External DNS
# --------------------------------------------------------------------


## Policy to allow external-dns to update recordsets in a given
## Hosted Zone in the same AWS account
data "aws_iam_policy_document" "external_dns_policy" {
  count = local.addon_create_policies["external-dns"] ? 1 : 0

  statement {
    sid    = "ExternalDNSChangeResourceRecordSets"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/*",
    ]
  }

  statement {
    sid    = "ExternalDNSListRoute53Resources"
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "external_dns_policy" {
  count = local.addon_create_policies["external-dns"] ? 1 : 0

  name        = "${var.environment}-EksExternalDNS"
  description = "Allow external-dns to update recordsets in Route53 hosted zones"
  policy      = data.aws_iam_policy_document.external_dns_policy[0].json
}

## Policy to allow external-dns to update recordsets in a given
## Hosted Zone in a remote AWS account (by assuming a cross-account role)
data "aws_iam_policy_document" "external_dns_cross_account_policy" {
  count = local.addon_create_policies["external-dns_cross-account"] ? 1 : 0

  statement {
    sid    = "ExternalDNSChangeRemoteRecordSets"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = local.addon_config["external-dns"].options.cross_account_access_role_arns
  }
}

resource "aws_iam_policy" "external_dns_cross_account_policy" {
  count = local.addon_create_policies["external-dns_cross-account"] ? 1 : 0

  name        = "${var.environment}-EksExternalDNSRemoteAccess"
  description = "Allow external-dns to update records in remote Route53 hosted zone(s)"
  policy      = data.aws_iam_policy_document.external_dns_cross_account_policy[0].json
}


# External DNS
data "aws_iam_policy_document" "external_dns_trust_policy" {
  count = local.addon_create_roles["external-dns"] ? 1 : 0

  statement {
    sid    = "EKSExternalDNSTrustPolicyStatement"
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

      values = [
        local.addon_fq_service_account_names["external-dns"],
        local.addon_fq_service_account_names["external-dns-private"]
      ]
    }
  }
}

resource "aws_iam_role" "external_dns_role" {
  count = local.addon_create_roles["external-dns"] ? 1 : 0

  name               = "${var.environment}-EksExternalDNSRole"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "external_dns_role_policy" {
  count = local.addon_attach_policies_to_irsa["external-dns"] ? 1 : 0

  policy_arn = aws_iam_policy.external_dns_policy[0].arn
  role       = aws_iam_role.external_dns_role[0].name
}

resource "aws_iam_role_policy_attachment" "external_dns_cross_account_role_policy" {
  count = local.addon_attach_policies_to_irsa["external-dns_cross-account"] ? 1 : 0

  policy_arn = aws_iam_policy.external_dns_cross_account_policy[0].arn
  role       = aws_iam_role.external_dns_role[0].name
}


# --------------------------------------------------------------------
# IAM Policies for EKS workers
# --------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "external_dns_policy" {
  count = local.addon_attach_policies_to_worker_role["external-dns"] ? 1 : 0

  policy_arn = aws_iam_policy.external_dns_policy[0].arn
  role       = aws_iam_role.k8s_workers_role.name
}

resource "aws_iam_role_policy_attachment" "external_dns_cross_account_policy" {
  count = local.addon_attach_policies_to_worker_role["external-dns_cross-account"] ? 1 : 0

  policy_arn = aws_iam_policy.external_dns_cross_account_policy[0].arn
  role       = aws_iam_role.k8s_workers_role.name
}