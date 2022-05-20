#
# Certificate: *.aws.binbash.com.ar
#
output "aws_binbash_com_ar_arn" {
  description = "The ARN of the certificate"
  value       = aws_acm_certificate.aws_binbash_com_ar.arn
}

#
# Certificate: *.devstg.aws.binbash.com.ar
#
output "certificate_wildcard_devstg_aws_binbash_com_ar_arn" {
  description = "Certificate ARN for *.devstg.aws.binbash.com.ar"
  value       = aws_acm_certificate.wildcard_devstg_aws_binbash_com_ar.arn
}
output "certificate_wildcard_devstg_aws_binbash_com_ar_domain_validation_options" {
  description = "Certificate Domain Validation Options for *.devstg.aws.binbash.com.ar"
  value       = aws_acm_certificate.wildcard_devstg_aws_binbash_com_ar.domain_validation_options
}
