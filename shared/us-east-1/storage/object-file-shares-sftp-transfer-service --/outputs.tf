output "user_usernames" {
  description = "Users' usernames"

  value = {
    for k, mod in var.users : k => mod.username
  }
}

output "server_custom_endpoint" {
  description = "Server Custome Endpoint"
  value       = aws_route53_record.main.name
}

output "server_endpoint" {
  description = "Server Endpoint"
  value       = module.sftp_server.sftp_server_endpoint
}
