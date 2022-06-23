#================================#
# Local variables                #
#================================#

#
# EC2 Attributes
#
variable "aws_ami_os_name" {
  type        = string
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "aws_ami_owner" {
  type        = string
  description = "The AWS account ID of the image owner, eg: 099720109477 for Canonical "
  default     = "099720109477"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.medium"
}

#
# Layer variables
#

# Name of instances to be launched
variable "ec2_instance_name" {
  type        = string
  description = "EC2 instance name"
  default     = "ec2-fleet-bastion"
}

# Name of Security Group
variable "ec2_security_group_name" {
  type        = string
  description = "Security Group name"
  default     = "ec2-fleet-bastion-security-group"
}

# Number of instances to be launched
variable "ec2_instances_count" {
  type        = number
  description = "EC2 instance count"
  default     = "2"
}

# List of IPs allowed to access throught the UDP port 3000
variable "allowed_ips_udp" {
  type        = list(string)
  description = "List of allowed IPs to access UDP 3000"
  default     = [""]
}

# List of IPs allowed to access throught the SSH port 22
variable "allowed_ips_ssh" {
  type        = list(string)
  description = "List of allowed IPs to access SSH"
  default     = [""]
}

# List of SSH public keys allowed to access to EC2 instances.
# Each key will be added as a entry on /home/ubuntu/.ssh/authorized_keys
variable "allowed_ssh_keys" {
  type        = list(string)
  description = "List of allowed keys to access throught SSH"
  default     = [""]
}
