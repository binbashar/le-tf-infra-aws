#
# Statics S3 Bucket + CloudFront CDN for moderncare.com
#
module "dev_aws_binbash_com_ar" {
  source = "github.com/binbashar/terraform-aws-cloudfront-s3-cdn.git?ref=0.23.1"

  # Common: bucket naming convention is "bb-apps-devstg-frontend-[DOMAIN_NAME]-origin"
  namespace = "${var.project}-${var.environment}-frontend"
  name      = local.domain_name
  stage     = "dev"
  aliases   = ["dev.${local.domain_name}"]

  # Certificate settings
  acm_certificate_arn = data.terraform_remote_state.certificates.outputs.aws_binbash_com_ar_arn
  price_class         = "PriceClass_100"

  # CloudFront settings
  enabled              = true
  compress             = true # Compress content for web reqs that include Accept-Encoding: gzip in the req header
  allowed_methods      = ["GET", "HEAD", "OPTIONS"]
  cached_methods       = ["GET", "HEAD", "OPTIONS"]
  default_ttl          = 60 # Default amount of time (in secs) that an obj. is in a CF cache
  geo_restriction_type = "none"
  min_ttl              = 0        # Min time objects stay in CF cache
  max_ttl              = 15552000 # Max time (in secs) an obj is in CF cache -> 180 days

  # S3 settings
  index_document  = "index.html"
  website_enabled = false # If you want to require that users always access your Amazon S3 content using CloudFront URLs,
  # not Amazon S3 URLs. This is useful when you are using signed URLs or signed cookies to restrict
  # access to your content. In the Help, see "Serving Private Content through CloudFront".
  origin_force_destroy     = true
  minimum_protocol_version = "TLSv1"
  encryption_enabled       = true

  logging_enabled     = true
  log_expiration_days = 90 # N° of days after which to expunge the objects

  # Tags
  tags = local.tags
}


# Here we need a different AWS provider because CloudFront certificates
# DNS dev.aws.binbash.com.ar associated with CF records needs to be created in
# binbash-shared account
#
resource "aws_route53_record" "priv_oring_dev_aws_binbash_com_ar" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-shared.outputs.aws_internal_zone_id[0]
  name     = "dev.${local.domain_name}"
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.dev_aws_binbash_com_ar.cf_domain_name
    zone_id                = module.dev_aws_binbash_com_ar.cf_hosted_zone_id
  }
}
