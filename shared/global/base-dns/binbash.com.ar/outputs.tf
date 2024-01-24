output "aws_public_zone_id" {
  description = "ID public DNS aws zone"
  value       = aws_route53_zone.aws_public_hosted_zone_1.id
}

output "aws_public_zone_domain_name" {
  description = "Public Hosted Zone Domain Name"
  value       = var.aws_public_hosted_zone_fqdn_1
}

output "aws_internal_zone_id" {
  description = "ID private DNSaws"
  value       = [aws_route53_zone.aws_private_hosted_zone_1.id]
}

output "aws_internal_zone_domain_name" {
  description = "Private Hosted Zone Domain Name"
  value       = var.aws_private_hosted_zone_fqdn_1
}
