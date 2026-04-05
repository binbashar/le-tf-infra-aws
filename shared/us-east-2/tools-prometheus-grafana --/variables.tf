#=============================#
# EC2 BASIC LAYOUT MODULE     #
#=============================#
#
# General
#
variable "prefix" {
  type        = string
  description = "Prefix"
  default     = "infra"
}

variable "name" {
  type        = string
  description = "Name"
  default     = "prometheus-dr"
}

#
# EC2 Attributes
#
# NOTE: when changing the OS version keep in mind:
# - You can get the AMI ID from this page: https://cloud-images.ubuntu.com/locator/ec2/
# - Then, using the ID, get the OS_ID (the aws_ami_os_id string) from here: https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images;v=3;$case=tags:false%5C,client:false;$regex=tags:false%5C,client:false
#     - Note you should look in public images
#     - Change the region to your desired one
# - IMPORTANT: when using UBUNTU prioritize LTS (Long Term Support) releases to ensure system stability and extended security updates!
#     - You can check releases here: https://en.wikipedia.org/wiki/Ubuntu_version_history
variable "aws_ami_os_id" {
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
}

variable "aws_ami_os_owner" {
  description = "AWS AMI Operating System Owner, eg: 099720109477 for Canonical "
  default     = "099720109477"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
  default     = "t3.medium"
}

variable "ebs_optimized" {
  type        = string
  description = "Enable EBS Optimized"
  default     = "false"
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address with the instance"
  default     = false
}

variable "root_device_backup_tag" {
  type        = string
  description = "EC2 Root Block Device backup tag"
  default     = "True"
}

variable "monitoring" {
  type        = bool
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  default     = false
}

variable "tag_approved_ami_value" {
  type        = string
  description = "Set the specific tag ApprovedAMI ('true' | 'false') that identifies aws-config compliant AMIs"
  default     = "true"
}
