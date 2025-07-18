output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = module.dynamodb_table.table_name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = module.dynamodb_table.table_arn
}