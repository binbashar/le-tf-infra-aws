output "instance_private_ip" {
  description = "EC2 private ip address"
  value       = module.vault_instance.aws_instance_private_ip
}

output "private_domain_name" {
  description = "Private domain name"
  value       = module.vault_instance.dns_record_private[0]
}

output "vault_backend_bucket_name" {
  description = "Vault backend bucket name"
  value       = module.vault_backend.this_s3_bucket_id
}
