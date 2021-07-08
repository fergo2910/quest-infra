# -------------------------------------------------------------
# ECR Module
# -------------------------------------------------------------

resource "aws_ecr_repository" "repo" {
  count                = var.create_repos ? length(var.repos) : 0
  name                 = var.repos[count.index].name
  image_tag_mutability = var.repos[count.index].mutable ? "MUTABLE" : "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = var.repos[count.index].image_scan
  }

  tags = merge(var.tags)
}

## ECR repo access policy
data "aws_iam_policy_document" "allow_ecr_access_policy" {
  version = "2012-10-17"

  statement {
    sid    = "AllowImagePullAndPush"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.allowed_account_ids
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
    ]
  }
}

resource "aws_ecr_repository_policy" "allow_access" {
  count      = var.resource_based_policy ? length(var.repos) : 0
  repository = aws_ecr_repository.repo[count.index].name
  policy     = data.aws_iam_policy_document.allow_ecr_access_policy.json
}