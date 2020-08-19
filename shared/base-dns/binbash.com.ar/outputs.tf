output "aws_public_zone_id" {
  description = "ID public DNS aws zone"
  value       = [aws_route53_zone.aws_public_hosted_zone_1.id]
}

output "aws_internal_zone_id" {
  description = "ID private DNSaws"
  value       = [aws_route53_zone.aws_private_hosted_zone_1.id]
}
