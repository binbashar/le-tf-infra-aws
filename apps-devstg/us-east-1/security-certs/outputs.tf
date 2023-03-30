#
# Certificate: *.aws.binbash.com.ar
#
output "certificate_arn" {
  description = "The certificate ARN"
  value       = aws_acm_certificate.main.arn
}
