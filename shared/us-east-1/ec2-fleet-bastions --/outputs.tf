output "public_ips" {
  description = "List of public IP addresses assigned to the instances"
  value       = module.ec2_bastion.*.public_ip
}

output "private_ips" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_bastion.*.private_ip
}