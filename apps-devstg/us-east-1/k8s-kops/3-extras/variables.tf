variable "traefik" {
  description = "Enable Traefik"
  type        = bool
}

variable "create_route53_record" {
  description = "Whether to create the Route53 record"
  type        = bool
  default     = true
}

variable "externaldns" {
  description = "Enable ExternalDNS"
  type        = bool
}
