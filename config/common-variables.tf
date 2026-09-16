#================================#
# Common variables               #
#================================#

#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "region_primary" {
  type        = string
  description = "AWS Region"
}

variable "regions_allowed" {
  type        = list(string)
  description = "List of allowed AWS regions"
  default     = ["us-east-1", "us-east-2", "us-west-2"]

  validation {
    condition = length(var.regions_allowed) > 0 && alltrue([
      for region in var.regions_allowed : can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", region))
    ])
    error_message = "regions_allowed must be a non-empty list of valid AWS region IDs (e.g., us-east-1)."
  }
}

variable "profile" {
  type        = string
  description = "AWS Profile (required by the backend but also used for other resources)"
}

variable "bucket" {
  type        = string
  description = "AWS S3 TF State Backend Bucket"
}

variable "dynamodb_table" {
  type        = string
  description = "AWS DynamoDB TF Lock state table name"
}

variable "encrypt" {
  type        = bool
  description = "Enable AWS DynamoDB with server side encryption"
}

#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
variable "project" {
  type        = string
  description = "Project Name"
}

variable "project_long" {
  type        = string
  description = "Project Long Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

#
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "region_secondary" {
  type        = string
  description = "AWS Secondary Region for HA"
}

variable "accounts" {
  type        = map(any)
  description = "Accounts Information"
}

variable "external_accounts" {
  type        = map(any)
  description = "External Accounts Information"
  default     = {}
}

#=============================#
# AWS SSO  Variables          #
#=============================#
variable "sso_role" {
  description = "SSO Role Name"
}

variable "sso_enabled" {
  type        = string
  description = "Enable SSO Service"
}

variable "sso_region" {
  type        = string
  description = "SSO Region"
}

variable "sso_start_url" {
  type        = string
  description = "SSO Start Url"
}

#===========================================#
# Networking                                #
#===========================================#
variable "enable_tgw" {
  description = "Enable Transit Gateway Support"
  type        = bool
  default     = false
}

variable "enable_tgw_multi_region" {
  description = "Enable Transit Gateway multi region support"
  type        = bool
  default     = false
}

variable "tgw_cidrs" {
  description = "CIDRs to be added as routes to public RT"
  type        = list(string)
  default     = []
}

#===========================================#
# Security compliance
#===========================================#
variable "enable_inspector" {
  description = "Turn inspector on/off"
  type        = bool
  default     = false
}

locals {
  regions = [var.region_primary, var.region_secondary, "global"]

  #Tries to find the current region for the current layer
  current_region = [for region in local.regions : region if can(regex(region, "${path.cwd}"))][0]

  #Split the full path of the layer using the region, in order to get the layer path (after the region)
  layer_name = replace(trimprefix(split(local.current_region, "${path.cwd}")[1], "/"), "/", "_")

  #===========================================#
  # PRM -- AWS Partner Revenue Measurement    #
  #===========================================#
  # `aws-apn-id = pc:<marketplace-product-code>` attributes AWS consumption to
  # an AWS Marketplace listing. Keyed by account: var.environment equals the
  # account directory name in every {account}/config/account.tfvars.
  #
  # Only Public, Active listings belong here -- a Restricted listing is
  # de-listed and does not satisfy the "at least one public listing"
  # requirement. Retrieve and check a code with:
  #
  #   aws marketplace-catalog describe-entity --catalog AWSMarketplace \
  #     --entity-id prod-xxxxxxxxxxxxx \
  #     --query 'DetailsDocument.[Description.ProductCode,Description.Visibility]' --output text
  prm_product_codes = {
    default        = "pc:5k5o9j3cjaqzpbiwt7ww6e65o" # Leverage | AWS Modernization (Containers / Serverless) -- prod-pkadanxklqjdc
    "data-science" = "pc:b6t445987ttlzwgcll8zdt8nv" # GenAI Assessment for Startups | AI/ML Readiness & Roadmap -- prod-zw4ehbg5ayh2m
  }

  prm_apn_id = lookup(local.prm_product_codes, var.environment, local.prm_product_codes["default"])
}

