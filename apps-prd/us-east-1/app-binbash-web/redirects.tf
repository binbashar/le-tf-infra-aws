#
# Wix -> binbash-web redirect map, served as 301s by the viewer-request
# CloudFront Function (see cloudfront-function.tf).
#
# WHY THIS EXISTS: 31 routes changed path in the migration out of Wix. Without
# these, every one of those URLs — all of them indexed, many of them linked
# from outside — 404s the moment DNS cuts over, throwing away the accumulated
# search ranking of the old site. 301 (not 302) is deliberate: it is the status
# that passes link equity to the new URL.
#
# SOURCE OF TRUTH: the 31 path-changing rows below are generated from the
# MIGRATED table in the app repo's own test,
# binbashar/bb-ai-sales-tools:apps/binbash-web/lib/content/__tests__/migrated-routes.test.ts,
# which the app repo keeps in step as pages migrate. Regenerate from there
# rather than editing rows by hand — that table has 53 entries, of which the
# 22 whose path did not change are correctly absent here.
#
# Values starting with "http" redirect off-site; everything else is a path on
# this distribution and keeps the request's query string (so utm_* campaign
# parameters survive the hop). Prefix retirements that cannot be expressed as
# exact matches — /post/* and /recipes/* — live in the function itself.
#
locals {
  # Routes whose path changed in the migration.
  wix_redirects_migrated = {
    "/aws-well-architected"               = "/services/aws-well-architected"
    "/careers"                            = "/people/careers"
    "/careers/awscloudengineer"           = "/people/careers/aws-cloud-engineer"
    "/careers/presales"                   = "/people/careers/presales-solutions-architect"
    "/careers/techdeliverymanager"        = "/people/careers/tech-delivery-manager"
    "/careers/usatechsales"               = "/people/careers/tech-sales-partner-usa"
    "/channel-partners"                   = "/partners/affiliate-partners"
    "/cloud-migration"                    = "/services/cloud-migration"
    "/cloud-partner"                      = "/partners"
    "/cloud-partner/cast-ai"              = "/partners/cast-ai"
    "/competition"                        = "/leverage/competition"
    "/founders"                           = "/people/founders"
    "/genai"                              = "/solutions/genai"
    "/genai/exclusivegenai"               = "/solutions/genai/exclusive-genai"
    "/how-we-work"                        = "/people/how-we-work"
    "/kashio"                             = "/case-studies/kashio"
    "/letsbuildyourstartup"               = "/events/lets-build-your-startup"
    "/robotics"                           = "/solutions/robotics"
    "/services-catalog"                   = "/solutions/services-catalog"
    "/services-catalog/cost-monitoring"   = "/solutions/services-catalog/cost-monitoring"
    "/services-catalog/datalake"          = "/solutions/services-catalog/data-lake"
    "/services-catalog/hipaa-framework"   = "/solutions/services-catalog/hipaa-framework"
    "/services-catalog/iso-27001"         = "/solutions/services-catalog/iso-27001"
    "/services-catalog/lakehouse-service" = "/solutions/services-catalog/lakehouse"
    "/services-catalog/landing-zone"      = "/solutions/services-catalog/landing-zone"
    "/services-catalog/security-baseline" = "/solutions/services-catalog/security-baseline"
    "/services-catalog/socii-framework"   = "/solutions/services-catalog/socii-framework"
    "/team"                               = "/people/team"
    "/team/fintech-squad"                 = "/people/team/fintech-squad"
    "/team/healthtech-squad"              = "/people/team/healthtech-squad"
    "/venture"                            = "/services/venture-capitals"
  }

  # Retirements: pages that are not coming back, pointed at whatever replaced
  # them. /blog and /post/* go to the Medium publication that superseded the
  # Wix blog; /testimonials goes to the Clutch profile that now carries the
  # reviews.
  wix_redirects_retired = {
    "/blog"         = "https://medium.com/binbash-inc"
    "/event-list"   = "/events"
    "/testimonials" = "https://clutch.co/profile/binbash"
    "/top-rated"    = "/"
  }

  wix_redirects = merge(local.wix_redirects_migrated, local.wix_redirects_retired)
}
