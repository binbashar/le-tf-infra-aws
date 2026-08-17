#
# Certificate: aws-startups-accelerate.binbash.co
#
output "aws_startups_accelerate_certificate_arn" {
  description = "The aws-startups-accelerate.binbash.co certificate ARN"
  value       = aws_acm_certificate.aws_startups_accelerate.arn
}

#
# Certificate: binbash.co + www.binbash.co (binbash-web production site)
#
output "binbash_web_certificate_arn" {
  description = "The binbash.co / www.binbash.co certificate ARN"
  value       = aws_acm_certificate.binbash_web.arn
}
