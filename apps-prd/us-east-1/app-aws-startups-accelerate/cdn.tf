#
# Static S3 Bucket + CloudFront CDN for aws-startups-accelerate.binbash.co
# (Next.js static export published by the app repo CI via `aws s3 sync`)
#
module "aws_startups_accelerate" {
  source = "github.com/binbashar/terraform-aws-cloudfront-s3-cdn.git?ref=v1.1.1"

  # Common: bucket naming convention is "[PROJECT]-[ENV]-[APP_SUBDOMAIN]"
  namespace = "${var.project}-${var.environment}"
  name      = local.app_subdomain
  aliases   = [local.app_fqdn]

  # Certificate settings (ACM cert in us-east-1, from the security-certs layer)
  acm_certificate_arn = data.terraform_remote_state.certificates.outputs.aws_startups_accelerate_certificate_arn
  price_class         = "PriceClass_100"

  # CloudFront settings
  enabled             = true
  compress            = true # Compress content for web reqs that include Accept-Encoding: gzip in the req header
  allowed_methods     = ["GET", "HEAD", "OPTIONS"]
  cached_methods      = ["GET", "HEAD"]
  default_root_object = "index.html"
  index_document      = "index.html"

  # Rewrite pretty URLs (/roadmap, /co-sell/, ...) to their index.html object
  function_association = [{
    event_type   = "viewer-request"
    function_arn = aws_cloudfront_function.pretty_urls.arn
  }]

  # Unknown paths return the app's 404 page
  # (with a private REST origin, S3 answers 403 AccessDenied for missing keys)
  custom_error_response = [
    {
      error_code            = 403
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 60
    },
    {
      error_code            = 404
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 60
    }
  ]

  # CloudFront access logs (dedicated bucket with lifecycle expiry)
  cloudfront_access_logging_enabled   = true
  cloudfront_access_log_create_bucket = true
  log_expiration_days                 = var.log_expiration_days

  # S3 settings: private origin reachable only through CloudFront (OAC)
  website_enabled                    = false
  origin_access_type                 = "origin_access_control"
  block_origin_public_access_enabled = true
  allow_ssl_requests_only            = true # Deny non-SSL requests via bucket policy
  encryption_enabled                 = true
  bucket_versioning                  = "Disabled"

  tags = local.tags
}
