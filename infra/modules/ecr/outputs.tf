output "repository_url" {
  description = "Fully qualified ECR URI (xxx.dkr.ecr.eu-central-1.amazonaws.com/repos)"
  value       = aws_ecr_repository.this.repository_url
}
