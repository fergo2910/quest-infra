# --------------------------------------------------------------------
# IAM Role and Policies for EKS (Kubernetes Control Plane)
# --------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "k8s_masters_role_policy_document" {
  statement {
    sid    = "EKSMasterTrustPolicy"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "k8s_masters_role" {
  name               = "${var.environment}-EksMastersRole"
  assume_role_policy = data.aws_iam_policy_document.k8s_masters_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s_masters_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.k8s_masters_role.name
}

# --------------------------------------------------------------------
# IAM Role and Policies for EKS workers
# --------------------------------------------------------------------

data "aws_iam_policy_document" "k8s_workers_role_role_policy_document" {
  statement {
    sid    = "EKSWorkerTrustPolicy"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "k8s_workers_role" {
  name               = "${var.environment}-EksWorkersRole"
  assume_role_policy = data.aws_iam_policy_document.k8s_workers_role_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s_workers_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = local.irsa_for_aws_vpc_cni ? aws_iam_role.aws_vpc_cni_role[0].name : aws_iam_role.k8s_workers_role.name
}

resource "aws_iam_role_policy_attachment" "container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8s_workers_role.name
}

resource "aws_iam_instance_profile" "iam_workers_profile" {
  name = "${var.environment}-EksWorkersProfile"
  role = aws_iam_role.k8s_workers_role.name
}

# --------------------------------------------------------------------
# Additional IAM Policies for EKS workers
# --------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "additional_policies" {
  count      = length(var.worker_role_additional_policies)
  policy_arn = var.worker_role_additional_policies[count.index]
  role       = aws_iam_role.k8s_workers_role.name
}

# --------------------------------------------------------------------
# IAM roles for service accounts
# --------------------------------------------------------------------

# AWS VPC CNI
data "aws_iam_policy_document" "aws_vpc_cni_trust_policy" {
  count = local.irsa_for_aws_vpc_cni ? 1 : 0

  statement {
    sid    = "EKSAWSVpcCNITrustPolicyStatement"
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
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
  }
}

resource "aws_iam_role" "aws_vpc_cni_role" {
  count = local.irsa_for_aws_vpc_cni ? 1 : 0

  name               = "${var.environment}-EksAWSVpcCNIRole"
  assume_role_policy = data.aws_iam_policy_document.aws_vpc_cni_trust_policy[0].json
}

# --------------------------------------------------------------------
# ADDITIONAL IAM roles for service accounts
# --------------------------------------------------------------------
data "aws_iam_policy_document" "additional_irsa_trust_policy" {
  for_each = var.additional_irsa

  statement {
    sid    = "IRSATrustPolicyStatement"
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
        local.irsa_additional_fq_service_account_names[each.key]
      ]
    }
  }
}

resource "aws_iam_role" "additional_irsa" {
  for_each = var.additional_irsa

  name               = "${var.environment}-${each.key}-EksRole"
  assume_role_policy = data.aws_iam_policy_document.additional_irsa_trust_policy[each.key].json
}

resource "aws_iam_role_policy_attachment" "additional_irsa_policy" {
  for_each = local.irsa_additional_policy_attachments

  policy_arn = each.value.policy_arn
  role       = each.value.role
}
