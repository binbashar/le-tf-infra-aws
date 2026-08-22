#
# Viewer-request CloudFront Function. Two jobs, in one function on purpose:
# CloudFront allows only ONE function per event type per cache behavior, so
# these cannot be two separate associations.
#
# 1. Serve the Wix -> binbash-web redirect map as 301s (see redirects.tf), plus
#    the two prefix retirements that cannot be written as exact matches.
#
# 2. Rewrite pretty URLs to the objects produced by the Next.js static export
#    (`output: "export"` + `trailingSlash: true`, which writes every route as
#    `{route}/index.html`):
#
#      /                     -> /index.html  (default root object)
#      /pricing/             -> /pricing/index.html
#      /solutions/ai-and-agents -> /solutions/ai-and-agents/index.html
#
# NOTE: this path layout must agree with the app's `trailingSlash` setting —
# with `trailingSlash: false` Next exports `{route}.html` instead and this
# function would need to append ".html" rather than "/index.html".
#
# Redirects are evaluated BEFORE the rewrite so an old Wix path never gets
# rewritten to an index.html that does not exist and 404s on the way past.
#
resource "aws_cloudfront_function" "pretty_urls" {
  name    = "${var.project}-${var.environment}-${local.app_name}-pretty-urls"
  runtime = "cloudfront-js-2.0"
  comment = "Wix->binbash-web 301 redirects + rewrite directory-style URIs to their index.html object"
  publish = true

  code = <<-EOT
    var REDIRECTS = ${jsonencode(local.wix_redirects)};

    var MEDIUM = 'https://medium.com/binbash-inc';

    // Rebuild the query string so utm_* campaign parameters survive an
    // internal redirect. request.querystring is an object, not a string.
    function query(request) {
      var q = request.querystring;
      var parts = [];
      for (var k in q) {
        var v = q[k].value;
        parts.push(v ? k + '=' + v : k);
      }
      return parts.length ? '?' + parts.join('&') : '';
    }

    function moved(location) {
      return {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
          'location': { value: location },
          'cache-control': { value: 'max-age=3600' }
        }
      };
    }

    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Look up without a trailing slash so /venture and /venture/ both match.
      var key = (uri.length > 1 && uri.endsWith('/')) ? uri.slice(0, -1) : uri;

      // --- 1. redirects -----------------------------------------------------
      var target = REDIRECTS[key];
      if (target) {
        // Off-site targets are absolute and get a clean URL; on-site targets
        // keep the query string.
        return moved(target.indexOf('http') === 0 ? target : target + query(request));
      }

      // Prefix retirements. The Wix blog lived at /post/<slug>; it is now the
      // Medium publication, which has no per-post mapping, so the whole prefix
      // collapses to the publication root. /recipes/* was Wix demo content
      // that was never ours and goes home.
      if (key === '/post' || key.indexOf('/post/') === 0) {
        return moved(MEDIUM);
      }
      if (key === '/recipes' || key.indexOf('/recipes/') === 0) {
        return moved('/' + query(request));
      }

      // --- 2. pretty URLs ---------------------------------------------------
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
