output "instance_count" {
  description = "Number of instances to launch specified as argument to this module"
  value       = module.ec2_fleet.instance_count
}

output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = module.ec2_fleet.public_dns
}

output "private_dns" {
  description = "List of private DNS names assigned to the instances. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC"
  value       = module.ec2_fleet.private_dns
}

output "private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_fleet.private_ip
}


