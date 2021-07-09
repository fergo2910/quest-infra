# --------------------------------------------------------------------
# K8S Cluster Autoscaler
# --------------------------------------------------------------------
locals {
  cluster_autoscaler_base_tags = {
    "k8s.io/cluster-autoscaler/enabled"                   = "true"
    "k8s.io/cluster-autoscaler/quest-${var.environment}" = "true"
  }

  cluster_autoscaler_mixed_label_tags = [for ng in var.mixed_workers_configuration :
    {
      "k8s.io/cluster-autoscaler/node-template/label/${element(split("=", lookup(ng, "node_labels", "")), 0)}" = element(split("=", lookup(ng, "node_labels", "")), 1)
    }
  ]

  cluster_autoscaler_ri_label__tags = {
    "k8s.io/cluster-autoscaler/node-template/label/${element(split("=", lookup(var.ri_worker_configuration, "node_labels", "")), 0)}" = element(split("=", lookup(var.ri_worker_configuration, "node_labels", "")), 1)
  }

  asg_mixed_name_tag = [for ng in var.mixed_workers_configuration :
    {
      Name = "${var.cluster_name}-${lookup(ng, "name", "mixed")}-worker"
    }
  ]

  asg_base_tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    var.tags,
    var.asg_tags
  )

}


data "aws_iam_policy_document" "cluster_autoscaler_trust_policy" {
  count = local.addon_create_roles["cluster-autoscaler"] ? 1 : 0

  statement {
    sid    = "EKSClusterAutoscalerTrustPolicyStatement"
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
        local.addon_fq_service_account_names["cluster-autoscaler"]
      ]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler_role" {
  count = local.addon_create_roles["cluster-autoscaler"] ? 1 : 0

  name               = "${var.environment}-EksClusterAutoscalerRole"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_trust_policy[0].json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_role_policy" {
  count = local.addon_attach_policies_to_irsa["cluster-autoscaler"] ? 1 : 0

  policy_arn = aws_iam_policy.autoscaler_policy[0].arn
  role       = aws_iam_role.cluster_autoscaler_role[0].name
}


## Policy to allow the K8S cluster auto-scaler feature to adjust the size of an ASG
data "aws_iam_policy_document" "autoscaling_policy" {
  count = local.addon_create_policies["cluster-autoscaler"] ? 1 : 0

  statement {
    sid    = "AutoScalingReadAccessForK8s"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid    = "AutoScalingWriteAccessForK8s"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    resources = aws_autoscaling_group.mixed-worker-nodes.*.arn
  }
}

resource "aws_iam_policy" "autoscaler_policy" {
  count = local.addon_create_policies["cluster-autoscaler"] ? 1 : 0

  name        = "${var.environment}-EksClusterAutoscaler"
  description = "Allows K8S cluster auto-scaler to adjust the ASG size"
  policy      = data.aws_iam_policy_document.autoscaling_policy[0].json
}


# --------------------------------------------------------------------
# IAM Policie for EKS workers
# --------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "autoscaler_policy" {
  count = local.addon_attach_policies_to_worker_role["cluster-autoscaler"] ? 1 : 0

  policy_arn = aws_iam_policy.autoscaler_policy[0].arn
  role       = aws_iam_role.k8s_workers_role.name
}