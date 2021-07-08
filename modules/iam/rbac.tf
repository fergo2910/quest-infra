resource "aws_iam_role" "k8s_admins_access" {
  name                = "${var.environment}-EKSAdminRBAC"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_role" "k8s_readonly_access" {
  name                = "${var.environment}-EKSReadOnlyRBAC"
  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

resource "aws_iam_role" "k8s_poweruser_access" {
  name                = "${var.environment}-EKSPowerUserRBAC"
  managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
}