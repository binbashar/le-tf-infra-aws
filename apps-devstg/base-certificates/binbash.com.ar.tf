resource "aws_acm_certificate" "wildcard_devstg_aws_binbash_com_ar" {
  domain_name       = "*.devstg.aws.binbash.com.ar"
  validation_method = "DNS"
}
