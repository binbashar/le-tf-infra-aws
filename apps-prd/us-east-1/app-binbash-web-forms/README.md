# app-binbash-web-forms

The AWS backend for the careers application form on www.binbash.co.

`binbash-web` is a static export (`output: 'export'`) and cannot have an API route, so the form
posts here instead. Design spec: `bb-sales-tools/docs/superpowers/specs/2026-09-08-careers-application-form-design.md`.

```
POST https://forms.binbash.co/careers-application
  → API Gateway HTTP API (CORS: www.binbash.co, binbash.co · throttle 5 rps / burst 10)
  → Lambda careers-application (python3.13)
  → SES  From careers@binbash.co  To people@binbash.com.ar  Reply-To: the applicant
```

## SES account status

Checked 2026-09-08 with `aws ses get-send-quota --region us-east-1`:

Not yet verified: `aws ses get-send-quota` needs an interactive SSO login this session could not perform. Assumed **production access**, because `apps-prd/us-east-1/app-ai-lab` already sends production notifications from this account. **Confirm before applying** — if `Max24HourSend` turns out to be `200.0`, the account is sandboxed, `people@binbash.com.ar` must be added as an `aws_ses_email_identity` and verified by hand, and `var.ses_sandbox` must be flipped to `true`.

No `ses.tf` in this layer — Task 10 decides whether to add one based on the verified quota.

## Apply order

This layer's custom domain needs a validated certificate, which lives elsewhere:

1. `apps-prd/us-east-1/security-certs` — creates and validates `forms.binbash.co`
2. this layer
3. the `bb-sales-tools` frontend PR — dead until `forms.binbash.co` resolves

## Known apply-time risk: API Gateway access logs

The stage sets `access_log_settings`, and API Gateway needs a CloudWatch Logs **resource
policy** allowing `apigateway.amazonaws.com` to write. Those policies are account-wide and
capped at 10 per account/region, so this layer deliberately does not create one — a second
policy would risk a conflict or exhausting the cap.

If the first `terraform apply` fails with `InvalidParameterException: CloudWatch Logs role
ARN must be set` or an access-log permission error, either point the stage at an existing
policy or drop the `access_log_settings` block. It is not load-bearing.

## What is deliberately not here

No datastore. An application that fails to send is lost; the CloudWatch alarm on the Lambda error
metric is the only signal. See spec §8.4 — this was a decision, not an omission.
