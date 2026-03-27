output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.binbash_co.arn
}

output "ses_domain_verification_status" {
  description = "SES domain verification status"
  value       = aws_ses_domain_identity_verification.binbash_co.id
}

output "ses_from_email" {
  description = "Verified sender email address"
  value       = aws_ses_email_identity.sender.email
}
