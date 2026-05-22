resource "aws_ecr_repository" "this" {
  name = var.repository_name
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}
