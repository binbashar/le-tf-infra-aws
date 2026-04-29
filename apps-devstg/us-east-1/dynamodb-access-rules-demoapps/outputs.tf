output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = module.dynamodb_table.table_name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = module.dynamodb_table.table_arn
}

output "aws_cognito_user_pool_endpoint" {
  value = aws_cognito_user_pool.user_pool.endpoint
}
output "aws_cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}
output "aws_cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.identity_pool.id
}

output "aws_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "aws_cognito_user_pool_client_client_secret" {
  value     = aws_cognito_user_pool_client.user_pool_client.client_secret
  sensitive = true
}