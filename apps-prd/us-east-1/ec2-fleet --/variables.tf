#=============================#
#  EC2 Attributes             #
#=============================#
variable "aws_ami_os_id" {
  type        = string
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "aws_ami_os_owner" {
  type        = string
  description = "AWS AMI Operating System Owner, eg: 099720109477 for Canonical "
  default     = "099720109477"
}

# security.tf file
#=============================#
#  SSM Attributes             #
#=============================#
variable "instance_profile" {
  type        = string
  description = "Whether or not to create the EC2 profile, use null or 'true'"
  default     = "true"
}

variable "prefix" {
  type        = string
  description = "EC2 profile prefix"
  default     = "fleet-ansible"
}

variable "name" {
  type        = string
  description = "EC2 profile name"
  default     = "ssm-demo"
}

variable "enable_ssm_access" {
  type        = bool
  description = "Whether or not to attach SSM policy to EC2 profile IAM role, use false or true"
  default     = true
}
