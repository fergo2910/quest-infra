data "aws_iam_policy_document" "ec2_sts_access_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
        "sts.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "k8s_admins_role" {
  name                = "${terraform.workspace}-EKSAdminRBAC"
  assume_role_policy  = data.aws_iam_policy_document.ec2_sts_access_policy.json
}

resource "aws_iam_role" "k8s_readonly_role" {
  name                = "${terraform.workspace}-EKSReadOnlyRBAC"
  assume_role_policy = data.aws_iam_policy_document.ec2_sts_access_policy.json
}

resource "aws_iam_role" "k8s_poweruser_role" {
  name                = "${terraform.workspace}-EKSPowerUserRBAC"
  assume_role_policy = data.aws_iam_policy_document.ec2_sts_access_policy.json
}

resource "aws_iam_role_policy_attachment" "admin_access_role" {
  role       = aws_iam_role.k8s_admins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "readonly_acces_role" {
  role       = aws_iam_role.k8s_readonly_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "poweruser_access_role" {
  role       = aws_iam_role.k8s_poweruser_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}