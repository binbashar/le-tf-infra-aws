# EC2 Private ip
output "aws_instance_private_ip" {
  description = "Contains the private IP address."
  value       = "${module.ec2_jenkins_vault.aws_instance_private_ip}"
}