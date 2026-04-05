#=============================#
#  EC2 Attributes             #
#=============================#
# NOTE: when changing the OS version keep in mind:
# - You can get the AMI ID from this page: https://cloud-images.ubuntu.com/locator/ec2/
# - Then, using the ID, get the OS_ID (the aws_ami_os_id string) from here: https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images;v=3;$case=tags:false%5C,client:false;$regex=tags:false%5C,client:false
#     - Note you should look in public images
#     - Change the region to your desired one
# - IMPORTANT: when using UBUNTU prioritize LTS (Long Term Support) releases to ensure system stability and extended security updates!
#     - You can check releases here: https://en.wikipedia.org/wiki/Ubuntu_version_history
variable "aws_ami_os_id" {
  type        = string
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
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
