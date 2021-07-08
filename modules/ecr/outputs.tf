output "repo_arn" {
  description = "arn of th ecr repo"
  value       = aws_ecr_repository.repo.*.arn
}

output "repo_name" {
  description = "name of th ecr repo"
  value       = aws_ecr_repository.repo.*.name
}
