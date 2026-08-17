# app-binbash-web

Serves **`binbash.co` and `www.binbash.co`** — the Next.js rebuild of the company
marketing site, migrated page-by-page out of Wix. Follows the Leverage **"app
frontend on AWS"** pattern: a fully static app served from a private S3 origin
behind CloudFront, deployed by the app repository's CI through a least-privilege
GitHub OIDC role — no long-lived AWS keys, near-zero monthly cost.

Second instance of the pattern established by
[`app-aws-startups-accelerate`](../app-aws-startups-accelerate/) (issue #1085);
this layer is issue #1141.

**Live since 2026-08-17.** Wix no longer serves these names.

## What this layer provisions

| Concern | Resources |
| --- | --- |
| **Serving** | CloudFront distribution (`PriceClass_100`, TLS 1.2+, compression) with a private S3 origin (OAC, SSE-S3, SSL-enforced, public access blocked); 403/404 mapped to the app's `404.html` |
| **Redirects + pretty URLs** | One viewer-request CloudFront Function serving the Wix→binbash-web 301 map and rewriting directory-style URLs to `index.html` |
| **DNS / TLS** | A/AAAA alias records for both names in the shared account public zone (cross-account `aws.shared-route53` provider); ACM certificate (`binbash.co` + SAN `www.binbash.co`) consumed from the `security-certs` layer via remote state |
| **Deploy identity** | Deploy role limited to `s3 sync` and CloudFront invalidation, trust scoped via the `sub` claim to `var.github_repository` @ `var.github_branch`. The account-wide GitHub OIDC provider is **looked up, not created** |
| **Operations** | CloudFront access logs (dedicated bucket, `var.log_expiration_days` expiry) and `5xxErrorRate` / `TotalErrorRate` CloudWatch alarms wired to the `notifications` layer SNS topic |
| **Phase 2 (disabled)** | `backend-stub.tf` documents the contact-form backend; intentionally not provisioned |

## Three things that differ from the layer this was cloned from

1. **`create_github_oidc_provider` defaults to `false` here.** There is one
   `aws_iam_openid_connect_provider` for `token.actions.githubusercontent.com`
   per AWS account and `app-aws-startups-accelerate` already owns it, so
   creating a second fails with `EntityAlreadyExists`. Issue #1081 covers moving
   ownership to a dedicated identities layer.

2. **Resources are named after `local.app_name` (`binbash-web`), not the
   hostname.** The bucket is `bb-apps-prd-binbash-web-origin`. Keeping the name
   independent of the hostname is why this layer could be built and verified
   against a staging hostname and then retargeted at production without
   recreating the bucket and re-syncing the site.

3. **The redirect map lives in the pretty-URL function.** CloudFront permits
   only one function per event type per cache behavior, so both jobs are merged
   into `cloudfront-function.tf`. Redirects are evaluated first, so an old Wix
   path is never rewritten to an `index.html` that does not exist.

## The redirect map (`redirects.tf`)

31 routes changed path in the migration out of Wix; without a 301 each of those
indexed URLs would 404 and the accumulated search ranking would be thrown away.
Four retirements are handled alongside (`/blog` and `/post/*` → the Medium
publication, `/testimonials` → the Clutch profile, `/event-list` → `/events`,
`/top-rated` and `/recipes/*` → `/`).

**The 31 path-changing rows are generated, not hand-written.** They come from the
`MIGRATED` table in the app repo's own test,
`bb-ai-sales-tools:apps/binbash-web/lib/content/__tests__/migrated-routes.test.ts`,
which the app repo keeps in step as pages migrate. Regenerate from there rather
than editing rows by hand — that table has 53 entries, of which the 22 whose path
did not change are correctly absent here.

Query strings survive internal redirects, so `utm_*` campaign attribution is not
lost on the hop. Off-site targets get a clean URL.

## Known gap: `/contact` returns 404

The app hardcodes `https://www.binbash.co/contact` in ~23 source files as a
placeholder that pointed at the **Wix** form. That hostname no longer serves Wix,
so every contact CTA on the site currently 404s. This was accepted deliberately at
cutover; the real page ships from the app repo separately. A row in `redirects.tf`
can point `/contact` at an interim destination in one apply if needed.

## The DNS cutover

`var.dns_cutover_enabled` gates the alias records in `dns.tf`. It was `false`
through build-out so the layer could be applied, deployed to and verified
end-to-end on the distribution's own `*.cloudfront.net` domain without moving live
traffic — `leverage tofu output verification_url` still prints that URL, which
remains the way to test a change before it reaches visitors.

The shared `base-dns` layer previously owned both names and had to give them up
first: Route 53 rejects an A record at a name that still has a CNAME, so `www` was
a destroy-then-create. See the ordering note in `dns.tf`. The apex MX (Google
Workspace) and TXT records are a different record type at the same name and were
unaffected.

## If an alarm fires

Both alarms gate on `var.alarm_min_requests_per_period`, so a fire means real
errors rather than scanner noise. Likely causes, in order:

1. The CloudFront Function failed at runtime — a function execution error
   surfaces to viewers as a `502`. Check `FunctionExecutionErrors` on
   `bb-apps-prd-binbash-web-pretty-urls` in CloudWatch.
2. The origin bucket lost its policy or OAC wiring, so CloudFront cannot read it.
3. A bad deploy left `/404.html` missing, so the custom error response itself fails.

Note `*ErrorRate` is computed from **the response's** status code, so anything the
viewer-request function returns itself counts. The 301s it serves today do not
(3xx is neither 4xx nor 5xx), but a future change returning 4xx directly would
move `TotalErrorRate` and this alarm would need rethinking at the same time.

Rollback is a redeploy: the bucket content is fully rebuildable from the app
repo's CI (`RPO` 0 — the source of truth is git; `RTO` is one workflow run).

## Deployment

1. Apply `apps-prd/us-east-1/security-certs` first — this layer consumes its
   ACM certificate ARN (`binbash_web_certificate_arn`) via `terraform_remote_state`.
   Note that layer currently fails on an unrelated expired certificate — issue #1143.
2. From this directory: `leverage tofu init && leverage tofu plan && leverage tofu apply`
   (requires valid `bb-apps-prd-devops` and `bb-shared-devops` credentials).

## Handoff to the app repository

Set as **repo Actions variables** on `binbashar/bb-ai-sales-tools`
(`Settings → Secrets and variables → Actions → Variables`). The `BINBASH_WEB_`
prefix is deliberate: both static-deploy workflows live in the same repo, and
unprefixed names would collide so each app deployed into the other's bucket.

| `leverage tofu output` | Repo variable |
| --- | --- |
| `s3_bucket` | `BINBASH_WEB_S3_BUCKET` |
| `cf_distribution_id` | `BINBASH_WEB_CF_DISTRIBUTION_ID` |
| `deploy_role_arn` | `BINBASH_WEB_AWS_DEPLOY_ROLE_ARN` |

## App-specific documentation

The application details (migration plan, CI deploy workflow, build requirements)
live in the app repository — private:
[`binbashar/bb-ai-sales-tools` → `apps/binbash-web`](https://github.com/binbashar/bb-ai-sales-tools/tree/main/apps/binbash-web)

Its `deploy-binbash-web.yml` runs a two-pass `s3 sync`: immutable `_next/static/`
assets first and never `--delete`d, then HTML with `--delete` and
`--exclude "_next/static/*"`, so a visitor mid-deploy on the previous build never
hits a `ChunkLoadError`. Nothing in this layer's bucket policy interferes with
that ordering.
