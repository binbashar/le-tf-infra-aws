#=============================#
# CDN DNS variables           #
#=============================#
variable "profile_shared" {
  type        = string
  description = "Shared account aws iam profile in order to update Route53 DNS service"
  default     = "bb-shared-devops"
}
