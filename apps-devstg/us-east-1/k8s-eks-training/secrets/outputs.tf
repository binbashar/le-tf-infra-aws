output "secret_arns" {
  description = "Secrets arns map"
  value       = module.secrets.secret_arns
}

output "secret_ids" {
  description = "Secrets ids map"
  value       = module.secrets.secret_ids
}
