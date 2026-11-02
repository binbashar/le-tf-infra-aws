output "ses_identity_arn" {
  description = "ARN of the SES domain identity the report sends from"
  value       = aws_sesv2_email_identity.domain.arn
}

output "dkim_records" {
  description = "DKIM CNAME records for the sending domain (add them by hand when manage_dns_records = false)"
  value = [
    for token in aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens : {
      name  = "${token}._domainkey.${var.ses_domain}"
      type  = "CNAME"
      value = "${token}.dkim.amazonses.com"
    }
  ]
}
