output "cluster_id" {
  value = aws_ecs_cluster.this.id
}
output "service_name" {
  value = aws_ecs_service.this.name
}
#  Commented due to user not being authorized to perform logs:ListTagsForResource
# output "log_group_name" {
#   value = aws_cloudwatch_log_group.app.name
# }
output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}
output "task_role_arn" {
  value = aws_iam_role.task.arn
}
