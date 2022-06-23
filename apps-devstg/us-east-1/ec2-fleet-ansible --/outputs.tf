output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = { for p in sort(keys(local.multiple_instances)) : p => module.ec2_ansible_fleet[p].id }
  # value = module.ec2_ansible_fleet["1"].id
}

output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = { for p in sort(keys(local.multiple_instances)) : p => module.ec2_ansible_fleet[p].public_dns }
}

output "private_dns" {
  description = "List of private DNS names assigned to the instances. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC"
  value       = { for p in sort(keys(local.multiple_instances)) : p => module.ec2_ansible_fleet[p].private_dns }
}

output "private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value       = { for p in sort(keys(local.multiple_instances)) : p => module.ec2_ansible_fleet[p].private_ip }
}

output "tags_all" {
  description = "Tags assigned to the instances"
  value       = { for p in sort(keys(local.multiple_instances)) : p => module.ec2_ansible_fleet[p].tags_all }
}
