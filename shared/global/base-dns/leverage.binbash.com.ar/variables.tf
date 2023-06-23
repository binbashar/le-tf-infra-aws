#
# Hosted Zones
#
variable "public_hosted_zone_fqdn" {
  type        = string
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "leverage.binbash.com.ar"
}
