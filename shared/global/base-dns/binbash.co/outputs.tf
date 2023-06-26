output "public_zone_id" {
  description = "Public Hosted Zone ID"
  value       = aws_route53_zone.public.id
}

output "public_zone_domain_name" {
  description = "Public Hosted Zone Domain Name"
  value       = var.public_hosted_zone_fqdn
}

output "private_zone_id" {
  description = "Private Hosted Zone ID"
  value       = aws_route53_zone.private.id
}

output "private_zone_domain_name" {
  description = "Private Hosted Zone Domain Name"
  value       = var.private_hosted_zone_fqdn
}
