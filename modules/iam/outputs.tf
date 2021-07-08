output "rbac_admin" {
  value = aws_iam_role.k8s_admins_access.arn
}

output "rbac_readonly" {
  value = aws_iam_role.k8s_readonly_access.arn
}

output "rbac_poweruser" {
  value = aws_iam_role.k8s_poweruser_access.arn
}

output "circle-ci-user-arn" {
  value = aws_iam_user.circle_ci_user.arn
}

output "circle-ci-user-name" {
  value = aws_iam_user.circle_ci_user.name
}