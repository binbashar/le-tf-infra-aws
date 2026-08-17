#
# Certificate: *.aws.binbash.com.ar
#
output "certificate_arn" {
  description = "The certificate ARN"
  value       = aws_acm_certificate.main.arn
}

#
# Certificate: aws-startups-accelerate.binbash.co
#
output "aws_startups_accelerate_certificate_arn" {
  description = "The aws-startups-accelerate.binbash.co certificate ARN"
  value       = aws_acm_certificate.aws_startups_accelerate.arn
}

#
# Certificate: www-next.binbash.co
#
output "binbash_web_certificate_arn" {
  description = "The www-next.binbash.co certificate ARN"
  value       = aws_acm_certificate.binbash_web.arn
}
