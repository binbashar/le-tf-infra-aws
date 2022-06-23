# EC2 Multiple
# https://github.com/binbashar/terraform-aws-ec2-instance/blob/v3.0.0/UPGRADE-3.0.md
# https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/blob/master/examples/complete/outputs.tf
# new way of show output form multiple_instances
# Renamed outputs:
# :info: All outputs used to be lists, and are now singular outputs due to the removal of count

output "ec2_multiple" {
  description = "The full output of the `ec2_module` module"
  value       = module.ec2_ansible_fleet
}
