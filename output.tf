
output "cloudwatch_log_group_name" {
  description = "The name of the cloudwatch log group for the ECS service"
  value       = aws_cloudwatch_log_group.main.name
}