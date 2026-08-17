#
# Viewer-request CloudFront Function. Does two jobs, in one function on purpose:
# CloudFront allows only ONE function per event type per cache behavior, so the
# staging gate cannot be a second viewer-request association — a second one is
# rejected, and the pretty-URL rewrite is not optional.
#
# 1. Staging access gate (removed at cutover — see staging.tf). Viewer-request
#    runs before the cache lookup, so the check is enforced on cache hits too.
#
# 2. Rewrite pretty URLs to the objects produced by the Next.js static export
#    (`output: "export"` + `trailingSlash: true`, which writes every route as
#    `{route}/index.html`):
#
#      /                     -> /index.html  (default root object)
#      /pricing/             -> /pricing/index.html
#      /solutions/genai      -> /solutions/genai/index.html
#
# NOTE: this path layout must agree with the app's `trailingSlash` setting —
# with `trailingSlash: false` Next exports `{route}.html` instead and this
# function would need to append ".html" rather than "/index.html".
#
# The function is cloned per app rather than shared with
# app-aws-startups-accelerate: the name is already namespaced per app, and
# sharing one would couple two apps' deploys for no benefit. The cutover
# redirect map (31 changed paths plus the retirements) most likely lands here.
#
resource "aws_cloudfront_function" "pretty_urls" {
  name    = "${var.project}-${var.environment}-${local.app_name}-pretty-urls"
  runtime = "cloudfront-js-2.0"
  comment = "Staging Basic-Auth gate + rewrite directory-style URIs to their index.html object"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;

      // --- staging access gate (remove at cutover, together with staging.tf) ---
      var auth = request.headers.authorization;
      if (!auth || auth.value !== '${local.staging_basic_auth_header}') {
        return {
          statusCode: 401,
          statusDescription: 'Unauthorized',
          headers: {
            'www-authenticate': { value: 'Basic realm="${local.app_fqdn} (staging)"' },
            'cache-control': { value: 'no-store' },
            'x-robots-tag': { value: 'noindex, nofollow' }
          }
        };
      }

      // --- pretty URLs ---
      var uri = request.uri;

      if (uri.endsWith('/')) {
        // Directory path: serve its index document
        request.uri = uri + 'index.html';
      } else if (!uri.split('/').pop().includes('.')) {
        // Extensionless path: treat it as a directory
        request.uri = uri + '/index.html';
      }

      return request;
    }
  EOT
}
