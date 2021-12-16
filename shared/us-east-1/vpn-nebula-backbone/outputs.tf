output "instance_count" {
  description = "Number of instances to launch specified as argument to this module"
  value       = module.ec2_vpn.instance_count
}

output "public_ips" {
  description = "List of public IP addresses assigned to the instances"
  value       = module.ec2_vpn.public_ip
}

output "private_ips" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_vpn.private_ip
}