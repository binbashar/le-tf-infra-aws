#===========================================#
# AWS Provider Settings                     #
#===========================================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#===========================================#
# Project Variables                         #
#===========================================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
  default = "dev"
}

variable "bucket" {}
variable "encrypt" {}
variable "cloudtrail_org_bucket" {}

#===========================================#
# Accounts                                  #
#===========================================#
variable "shared_account_id" {
  description = "Account: Shared Resources"
}

#===========================================#
# External Accounts Data                    #
#===========================================#
variable "security_account_id" {
  description = "Security & Users Management Account ID"
}

variable "dev_account_id" {
  description = "Dev/Stage Account ID"
}

#===========================================#
# Networking                                #
#===========================================#
variable "vpc_shared_created" {
  description = "true if Shared account VPC is created"
  type        = bool
  default     = true
}

variable "vpc_dev_eks_created" {
  description = "true if Dev account EKS VPC is created"
  type        = bool
  default     = false
}