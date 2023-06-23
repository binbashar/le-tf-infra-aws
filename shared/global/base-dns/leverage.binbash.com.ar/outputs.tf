output "public_zone_id" {
  description = "Public Hosted Zone ID"
  value       = aws_route53_zone.public.id
}

output "public_zone_domain_name" {
  description = "Public Hosted Zone Domain Name"
  value       = var.public_hosted_zone_fqdn
}

output "public_zone_domain_ns_records" {
  description = "Public Hosted Zone Domain Name"
  value       = aws_route53_zone.public.name_servers
}
