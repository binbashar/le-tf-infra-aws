#
# Hosted Zones
#
variable "public_hosted_zone_fqdn" {
  type        = string
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "binbash.co"
}

variable "private_hosted_zone_fqdn" {
  type        = string
  description = "AWS Route53 private hosted zone fully qualified domain name (fqdn)"
  default     = "aws.binbash.co"
}
