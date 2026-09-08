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

Verified 2026-09-08 against apps-prd/us-east-1:

```
aws sesv2 get-account
  ProductionAccessEnabled  true        <- authoritative; not the sandbox
  SendingEnabled           true
  EnforcementStatus        HEALTHY

aws ses get-send-quota
  Max24HourSend            50000.0     the sandbox cap is 200.0
  MaxSendRate              14.0 /sec

aws ses get-identity-dkim-attributes --identities binbash.co
  DkimEnabled              true
  DkimVerificationStatus   Success
```

The account has **SES production access**, so `var.ses_sandbox` correctly defaults to `false` and
recipients need no verification of their own. The `binbash.co` domain identity is verified with DKIM
(by `apps-prd/us-east-1/app-ai-lab`), which is what lets `ses_from_email` be any `@binbash.co`
address without further setup. `people@binbash.com.ar` is deliberately *not* a verified identity —
outside the sandbox it does not need to be.

`ses.tf` is therefore inert as configured: gated on `var.ses_sandbox`, it creates nothing. It stays in
the tree because SES production access is an account-level grant AWS can revoke, and if that ever
happens flipping the variable to `true` creates an `aws_ses_email_identity` for
`var.careers_recipient` — which a human must then verify by clicking the link AWS emails, or mail to
that address is rejected outright.

`MaxSendRate` of 14/sec also puts the stage throttle in context: at 1 rps this layer can consume at
most ~7% of the account's per-second send rate, leaving headroom for `app-ai-lab`'s notifications,
which share the quota.

## Apply order

This layer's custom domain needs a validated certificate, which lives elsewhere:

1. `apps-prd/us-east-1/security-certs` — creates and validates `forms.binbash.co`
2. this layer
3. the `bb-sales-tools` frontend PR — dead until `forms.binbash.co` resolves

The SES send quota no longer gates step 1 — it is confirmed as production access above.

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

## Alarms

`monitoring.tf` defines two alarms, both notifying the `notifications` layer's SNS -> Lambda ->
Slack topic (`sns_topic_arn_monitoring`) — the same pipeline `app-binbash-web/monitoring.tf` uses.

| Alarm | Fires when | Source |
|---|---|---|
| `…-send-failures` | An application was accepted but never emailed — the submission is **lost** | Log metric filter on the Lambda's log group |
| `…-function-errors` | The invocation never completed: timeout, OOM, cold-start import failure | `AWS/Lambda` `Errors` |

**Why the first one reads the log group instead of the `Errors` metric.** `lambda_handler` catches
every exception and *returns* a 500 payload rather than letting it escape, so to Lambda a failed SES
send is a **successful invocation** — `Errors` stays at 0 through exactly the failure this layer most
needs to know about. An `Errors >= 1` alarm alone would have been decorative. The two alarms cover
disjoint halves: one for "the function answered 500", one for "the function never answered".

The metric filter matches the literal strings `SES send failed` and `unhandled error in
lambda_handler`. **Those are a contract with `lambda_function.py`** — renaming either
`LOGGER.exception()` message silently disarms the alarm, and no test or compiler will catch it.

## What is deliberately not here

No datastore. An application that fails to send is not recoverable from anywhere — the alarms above
tell you it happened and the Lambda's log group has the traceback, but the submission itself is gone.
See spec §8.4: that was a decision, not an omission.
