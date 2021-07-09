data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm_access" {
  policy_id = "SSM_access_from_cicd_${terraform.workspace}"
  version   = "2012-10-17"
  statement {
    sid    = "getParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${upper(terraform.workspace)}/REARC/*",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${upper(terraform.workspace)}/REARC/"
    ]
  }
  statement {
    sid       = "describeParameters"
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
  # Statement for System Manager Session Manager host
  statement {
    sid    = "startSession"
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:GetConnectionStatus",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecr_access" {
  policy_id = "ECR_access_from_cicd_${terraform.workspace}"
  version   = "2012-10-17"
  statement {
    sid    = "ecrAccess"
    effect = "Allow"
    actions = [
      "ecr:PutImageTagMutability",
      "ecr:StartImageScan",
      "ecr:ListTagsForResource",
      "ecr:UploadLayerPart",
      "ecr:ListImages",
      "ecr:PutRegistryPolicy",
      "ecr:CompleteLayerUpload",
      "ecr:TagResource",
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:ReplicateImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRegistryPolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:DescribeImageScanFindings",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:CreateRepository",
      "ecr:DescribeRegistry",
      "ecr:PutImageScanningConfiguration",
      "ecr:GetDownloadUrlForLayer",
      "ecr:PutImage",
      "ecr:UntagResource",
      "ecr:SetRepositoryPolicy",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:StartLifecyclePolicyPreview",
      "ecr:InitiateLayerUpload",
      "ecr:GetRepositoryPolicy",
      "ecr:PutReplicationConfiguration"
    ]
    resources = ["arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/quest"]
  }
  statement {
    sid    = "ecrAccessAllResources"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "eks_access" {
  policy_id = "EKS_access_from_cicd_${terraform.workspace}"
  version   = "2012-10-17"
  statement {
    sid    = "eksAccess"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
    ]
    resources = [
      "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/rearc-${terraform.workspace}"
    ]
  }
}

resource "aws_iam_user" "circle_ci_user" {
  name = "circle-ci-access-${terraform.workspace}"
  path = "/"
}

resource "aws_iam_access_key" "circle_ci_access_keys" {
  user = aws_iam_user.circle_ci_user.name
}

resource "aws_ssm_parameter" "circle_ci_access_key_id" {
  name        = upper("/${terraform.workspace}/REARC/CIRCLE_CI_ACCESS_KEY")
  description = "circle_ci access key id to be used by circle ci"
  type        = "SecureString"
  value       = aws_iam_access_key.circle_ci_access_keys.id
}

resource "aws_ssm_parameter" "circle_ci_secret_access_key_id" {
  name        = upper("/${terraform.workspace}/REARC/CIRCLE_CI_SECRET_ACCESS_KEY")
  description = "circle_ci secret access key id to be used by circle ci"
  type        = "SecureString"
  value       = aws_iam_access_key.circle_ci_access_keys.secret
}

resource "aws_iam_policy" "circle-ci-access-ssm-policy" {
  name   = "ssm_access_policy_${terraform.workspace}"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm_access.json
}

resource "aws_iam_user_policy_attachment" "circle-ci-access" {
  user       = aws_iam_user.circle_ci_user.name
  policy_arn = aws_iam_policy.circle-ci-access-ssm-policy.arn
}

resource "aws_iam_user_policy" "circle-ci-access-ecr-policy" {
  name   = "ecr_access_policy_${terraform.workspace}"
  user   = aws_iam_user.circle_ci_user.name
  policy = data.aws_iam_policy_document.ecr_access.json
}

resource "aws_iam_user_policy" "circle-ci-access-eks-policy" {
  name   = "eks_access_policy_${terraform.workspace}"
  user   = aws_iam_user.circle_ci_user.name
  policy = data.aws_iam_policy_document.eks_access.json
}