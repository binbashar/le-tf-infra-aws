# app-binbash-web-forms

The AWS backend for the careers application form on www.binbash.co.

`binbash-web` is a static export (`output: 'export'`) and cannot have an API route, so the form
posts here instead. Design spec: `bb-sales-tools/docs/superpowers/specs/2026-09-08-careers-application-form-design.md`.

```
POST https://forms.binbash.co/careers-application
  → API Gateway HTTP API (CORS: www.binbash.co, binbash.co · throttle 1 rps / burst 10)
  → Lambda careers-application (python3.13)
  → SES  From careers@binbash.co  To people@binbash.com.ar  Reply-To: the applicant
```

## SES account status

Attempted 2026-09-08 with `aws ses get-send-quota --region us-east-1`:

Not yet verified: `aws ses get-send-quota` needs an interactive SSO login this session could not perform. Assumed **production access**, because `apps-prd/us-east-1/app-ai-lab` already sends production notifications from this account. **Confirm before applying** — if `Max24HourSend` turns out to be `200.0`, the account is sandboxed, `people@binbash.com.ar` must be added as an `aws_ses_email_identity` and verified by hand, and `var.ses_sandbox` must be flipped to `true`.

`ses.tf` exists but is gated on `var.ses_sandbox`, which defaults to `false` on the assumption of
production access above. If the quota check later shows the account is sandboxed, flipping that
variable to `true` creates an `aws_ses_email_identity` for `var.careers_recipient` — a human must
then verify it by clicking the link AWS emails, or mail to that address is rejected outright.

## Apply order

This layer's custom domain needs a validated certificate, which lives elsewhere:

1. Confirm the SES send quota (see [SES account status](#ses-account-status) above) — if the
   account turns out to be sandboxed, `var.ses_sandbox` must be flipped to `true` before
   applying, or the recipient identity will not exist and mail will be rejected outright.
2. `apps-prd/us-east-1/security-certs` — creates and validates `forms.binbash.co`
3. this layer
4. the `bb-sales-tools` frontend PR — dead until `forms.binbash.co` resolves

## API Gateway access logs

This is an HTTP API (v2), not a REST API (v1) — the account-wide CloudWatch Logs role ARN
and resource-policy setup that v1 requires (`aws_api_gateway_account`, a policy for
`apigateway.amazonaws.com` capped at 10 per account/region) does not apply here. HTTP API
delivers access logs as CloudWatch vended logs: AWS grants `delivery.logs.amazonaws.com`
write access to the destination log group itself, scoped to that one log group, the first
time a stage's `access_log_settings` targets it — no resource policy of ours to write or
collide with. `apps-devstg/us-east-1/tools-apigw-apps-proxy --` uses the same shape
(`default_stage_access_log_destination_arn` pointed at a plain `aws_cloudwatch_log_group`,
no resource policy), but that layer's trailing ` --` marks it disabled and excluded from
deployment and Atlantis autodiscover, so it has never actually been applied. It is a code
reference for the mechanism, not a working precedent.

The `format` map is still worth double-checking on a first apply: a misspelled `$context`
variable does not error, it just delivers an empty field for that key. If access logging
still blocks the apply for some other reason, dropping the `access_log_settings` block is
a safe escape hatch — it is not load-bearing for the route itself.

## What is deliberately not here

No datastore, and no metric alarm. An application that fails to send is lost, with only the
Lambda's own CloudWatch logs as evidence after the fact — nothing pages anyone when it happens.
See spec §8.4 — the absence of a datastore was a decision, not an omission.

A CloudWatch metric alarm on the function's `Errors` metric, wired to SNS following the pattern in
`apps-prd/us-east-1/app-binbash-web/monitoring.tf`, is the obvious next step for closing that gap.
It is not implemented here: Tasks 7-10 did not ask for one, and adding production monitoring is a
scope call for the repo owner, who has been asked and has not yet answered. Treat this as an open
decision, not a planned or committed piece of work.
