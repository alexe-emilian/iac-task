resource "aws_ecr_repository" "this" {
  name = "${var.project}-${var.env}"   # e.g. iac-task-dev

  image_scanning_configuration { scan_on_push = true }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "expire" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire images older than 30 days"
      selection    = {
        tagStatus   = "any"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 30
      }
      action = { type = "expire" }
    }]
  })
}
