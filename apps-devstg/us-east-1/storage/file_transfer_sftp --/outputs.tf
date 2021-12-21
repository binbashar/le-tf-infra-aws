output "customers_usernames" {
  description = "Customers' usernames"

  value = {
    for k, mod in var.customers : k => mod.username
  }
}

output "server_custom_endpoint" {
  description = "Server Custome Endpoint"
  value       = aws_route53_record.main.name
}

output "server_endpoint" {
  description = "Server Endpoint"
  value       = module.customer_sftp.sftp_server_endpoint
}
