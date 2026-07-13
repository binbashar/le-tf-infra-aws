#
# Viewer-request CloudFront Function: rewrite pretty URLs to the objects
# produced by the Next.js static export (`output: "export"` + `trailingSlash: true`,
# which writes every route as `{route}/index.html`):
#
#   /            -> /index.html  (default root object)
#   /roadmap     -> /roadmap/index.html
#   /co-sell/    -> /co-sell/index.html
#
# NOTE: this path layout must agree with the app's `trailingSlash` setting —
# with `trailingSlash: false` Next exports `{route}.html` instead and this
# function would need to append ".html" rather than "/index.html".
#
resource "aws_cloudfront_function" "pretty_urls" {
  name    = "${var.project}-${var.environment}-${local.app_subdomain}-pretty-urls"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite directory-style URIs to their index.html object"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;
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
