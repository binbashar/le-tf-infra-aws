output "instance_public_ip" {
  description = "EC2 private ip address"
  value       = module.terraform-aws-basic-layout.aws_instance_public_ip
}

output "instance_private_ip" {
  description = "EC2 private ip address"
  value       = module.terraform-aws-basic-layout.aws_instance_private_ip
}

output "private_domain_name" {
  description = "Private domain name"
  value       = module.terraform-aws-basic-layout.dns_record_private
}
