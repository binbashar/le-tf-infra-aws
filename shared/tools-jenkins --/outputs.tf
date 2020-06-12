output "instance_private_ip" {
  description = "EC2 private ip address"
  value       = module.jenkins_master.aws_instance_private_ip
}

output "private_domain_name" {
  description = "Private domain name"
  value       = aws_route53_record.private_domain.fqdn
}