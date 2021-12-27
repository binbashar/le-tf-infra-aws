output "public_ips" {
  description = "List of public IP addresses assigned to the instances"
  value       = aws_eip.bastion_instance.*.public_ip
}

output "public_dns" {
  description = "Public DNS associated with the Elastic IP address"
  value       = aws_eip.bastion_instance.*.public_dns
}

output "private_ips" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_bastion.*.private_ip
}