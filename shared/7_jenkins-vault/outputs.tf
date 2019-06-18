# EC2 Private ip
output "private_ip" {
  description = "Contains the private IP address."
  value       = "${module.ec2_jenkins_vault.private_ip}"
}