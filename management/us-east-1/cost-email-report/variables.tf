#=================#
# Layer Variables #
#=================#

variable "ses_domain" {
  description = "Domain the report is sent from, verified in SES with Easy DKIM (e.g. binbash.com.ar). The sender address is any mailbox under it."
  type        = string
  default     = "binbash.com.ar"
}

variable "manage_dns_records" {
  description = "Create the DKIM CNAME records in the Route53 zone reached through the aws.dns provider. Set to false when the domain's DNS is not in Route53, and add the records from the dkim_records output by hand."
  type        = bool
  default     = true
}
