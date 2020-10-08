#
# Statics S3 Bucket + CloudFront CDN for moderncare.com
#
module "www_binbash_com_ar_statics" {
  source = "github.com/binbashar/terraform-aws-cloudfront-s3-cdn.git?ref=0.34.0"

  # Common: bucket naming convention is "[PROJECT]-[ENV]-statics-[DOMAIN_NAME]"
  namespace = "${var.project}-${var.environment}-statics"
  name      = local.public_domain_name
  aliases   = ["statics.${local.public_domain}"]

  # Certificate settings
  acm_certificate_arn = data.terraform_remote_state.certificates.outputs.binbash_com_ar_arn
  price_class         = "PriceClass_100"

  # CloudFront settings
  enabled              = true
  compress             = true # Compress content for web reqs that include Accept-Encoding: gzip in the req header
  allowed_methods      = ["GET", "HEAD", "OPTIONS"]
  cached_methods       = ["GET", "HEAD", "OPTIONS"]
  default_ttl          = 60 # Default amount of time (in secs) that an obj. is in a CF cache
  geo_restriction_type = "none"
  min_ttl              = 0      # Min time objects stay in CF cache
  max_ttl              = 604800 # Max time (in secs) an obj is in CF cache -> 7 days

  # S3 settings
  origin_force_destroy = true
  cors_allowed_origins = ["www.${local.public_domain}", local.public_domain]
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET", "HEAD"]

  tags = local.tags
}

# Here we need a different AWS provider because CloudFront certificates
# DNS statics.binbash.com.ar associated with CF records needs to be created in
# binbash-shared account
#
resource "aws_route53_record" "pub_A_statics_binbash_com_ar" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-shared.outputs.aws_public_zone_id[0]
  name     = "statics.${local.public_domain}"
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.www_binbash_com_ar_statics.cf_domain_name
    zone_id                = module.www_binbash_com_ar_statics.cf_hosted_zone_id
  }
}
