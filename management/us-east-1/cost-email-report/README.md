# Monthly cost email report

Monthly AWS cost report by email, sent from the management (payer) account. The
layer is both binbash's own report and the **reference code** we copy into client
repositories. Design and decisions: [#1299](https://github.com/binbashar/le-tf-infra-aws/pull/1299)
(`docs/monthly-cost-email/design.md`), for #1297.

> **Status: step 1 of 3, SES only.** This layer currently sets up the sending domain.
> The report itself (Lambda, schedule, recipients) comes next. Until then the old
> report keeps running from `shared/us-east-1/tools-costs-email-notifications`.

## What it creates

| Resource | Purpose |
|---|---|
| `aws_sesv2_email_identity.domain` | `var.ses_domain` as an SES **domain** identity with Easy DKIM (2048-bit). Any address under the domain can send |
| `aws_route53_record.dkim` (×3) | The DKIM `CNAME` records, in the domain's public zone through the `aws.dns` provider (the `shared` account for `binbash.com.ar`) |

SES signs with `d=<ses_domain>`, so DMARC passes on DKIM alignment. The envelope
`MAIL FROM` stays on `amazonses.com`, so the domain's SPF record needs no change.

## Install

The `aws` commands below must run against the **management account** in **us-east-1**;
`put-account-details` in the wrong account or region requests production access there
instead. With Leverage's credentials (adjust the profile in a client installation):

```bash
export AWS_CONFIG_FILE=~/.aws/bb/config AWS_SHARED_CREDENTIALS_FILE=~/.aws/bb/credentials
export AWS_PROFILE=bb-management-administrator AWS_REGION=us-east-1
aws sts get-caller-identity --query Account   # must be the management account
```

1. `leverage tofu apply` from this directory.
2. Wait for verification (usually minutes, up to 72 hours after the records resolve):
   ```bash
   aws sesv2 get-email-identity --email-identity <ses_domain> \
     --query '{verified:VerifiedForSendingStatus,dkim:DkimAttributes.Status}'
   ```
3. **Request SES production access, once per account and region.** The AWS provider has
   no resource for it. Until it is granted, SES is in the sandbox: 200 messages a day,
   and every recipient must be a verified identity.
   ```bash
   aws sesv2 put-account-details \
     --production-access-enabled \
     --mail-type TRANSACTIONAL \
     --website-url https://<company website> \
     --contact-language EN \
     --use-case-description "One internal monthly AWS cost report per month, sent from <ses_domain> to a handful of the organization's own mailboxes. No marketing, no lists. Bounces and complaints are handled by the account owner."
   ```
   AWS answers through a support case, usually within a day. Check with
   `aws sesv2 get-account --query '{prod:ProductionAccessEnabled,review:Details.ReviewDetails}'`.

## In a client installation

- Set `ses_domain` to the client's domain.
- Point the `aws.dns` provider and `data.terraform_remote_state.dns` at the account that
  holds the client's public zone. If their DNS is not in Route53, set
  `manage_dns_records = false` and hand them the `dkim_records` output.
- Request production access in the client's management account (step 3 above).
