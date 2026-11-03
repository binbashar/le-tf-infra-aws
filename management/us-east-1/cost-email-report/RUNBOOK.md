# Monthly cost email report: client installation runbook

How to install this layer in a client's Leverage repository. The client's repository
follows the Leverage reference architecture: a `management` account that is the
organization's payer, a `shared` account, `build.env` with `PROJECT`, and each account's
`config/backend.tfvars`. Who receives the report, and whether binbash gets a copy and
until when, is agreed in the statement of work.

In the commands below, `<project>` is the client's `PROJECT` and `binbash/` and `client/`
are local checkouts of `le-tf-infra-aws` and the client's repository.

## 1. Before you start

- [ ] **Cost Explorer is enabled** in the client's management account (Billing and Cost
      Management → Cost Explorer). The first time, it takes up to 24 hours to have data.
- [ ] You can run Leverage against the client's **management** account, and the account
      that holds the sending domain's public Route53 zone (usually **shared**):
      `leverage aws sso login`.
- [ ] **The sending domain**, e.g. `client.com`. The sender is any address under it, and
      every recipient must be under it too (see [SES sandbox](README.md#ses-sandbox-is-production-access-needed)
      for recipients on other domains). Find the layer that owns its zone: by convention
      `shared/global/base-dns/<domain>`, with state key `shared/dns/<domain>/terraform.tfstate`
      and an `aws_public_zone_id` output.
- [ ] **A monitoring SNS topic** for the error alarm: by convention
      `management/us-east-1/notifications`, with a `sns_topic_arn_monitoring` output.
- [ ] Optional: the name of a monthly **budget** to show, and a **cost allocation tag**
      already activated in Billing to measure untagged spend.

## 2. Copy the layer

Copy it from the latest `master` of `le-tf-infra-aws`. `git archive` copies only tracked
files (no `.terraform/` or `builds/`) and keeps the `common-variables.tf` symlink:

```bash
git -C binbash fetch origin
git -C binbash archive origin/master management/us-east-1/cost-email-report | tar -x -C client
```

Add the layer to the client's `infracost.yml`, like its other layers.

## 3. Adapt it

Rewrite `report.auto.tfvars`. It holds everything that belongs to the installation:

```hcl
ses_domain  = "client.com"
dns_account = "shared"            # the account that holds the zone

organization_name = "Client"      # shown in the subject: [Client] AWS cost report — October 2026
sender            = "Client FinOps <finops@client.com>"
recipients        = ["cfo@client.com", "devops@client.com"]

budget_name      = "budget-MONTHLY-management-100-percent"   # or omit it: no budget line
untagged_tag_key = "CostCenter"   # or omit it: no untagged spend line

# Only if the statement of work includes the binbash copy
binbash_recipients      = ["finops@binbash.com.ar"]
binbash_reporting_until = "2027-06-30"   # the contract's last day, inclusive
```

Other variables have defaults that fit most installations (see `variables.tf`):

| When | Set |
|---|---|
| The zone's layer does not follow `<dns_account>/dns/<domain>/terraform.tfstate` | `dns_state_key` |
| The domain's DNS is not in Route53 | `manage_dns_records = false`, `dns_account = "management"`; give the client the `dkim_records` output to add by hand |
| The alarm should notify another topic than the monitoring one | `alarm_sns_topic_arn` |
| Another day or time | `schedule_expression` (UTC) |

Check that the client's `config/common-variables.tf` defines the locals that `locals.tf`
uses for tags: `layer_name` and `prm_apn_id`. An older repository may lack them: drop the
missing tag from `locals.tf` rather than adding it.

## 4. Special cases

**The domain is already an SES identity in the management account** (used by something
else). Import it instead of creating it, and keep it on uninstall (see step 6):

```bash
cd client/management/us-east-1/cost-email-report
leverage tofu import aws_sesv2_email_identity.domain client.com
```

If its DKIM records already exist in the zone, import them as well
(`aws_route53_record.dkim[0..2]`, id `<zone_id>_<name>_CNAME`), or the apply fails
because they exist.

**The domain's DNS is not in Route53.** See the table in step 3. The identity is verified
once the client adds the three `CNAME` records.

## 5. Install and verify

From `client/management/us-east-1/cost-email-report`:

1. `leverage tofu init` and `leverage tofu plan`. Expect only additions. Open the PR
   with the plan as the client's repository requires, and apply after approval:
   `leverage tofu apply`.
2. Wait until SES verifies the domain (minutes, up to 72 hours after the records resolve).
   With the management account's credentials (see [Install](README.md#install)):
   ```bash
   aws sesv2 get-email-identity --email-identity client.com \
     --query '{verified:VerifiedForSendingStatus,dkim:DkimAttributes.Status}'
   ```
   Go on when it shows `true` and `SUCCESS`.
3. **Send to one address first.** This builds the report from the checkout, with real
   data, and sends it only to the address given:
   ```bash
   tests/send_test_report.sh you@client.com
   ```
   Check that it arrives, outside spam, and that the totals match the console.
4. **Invoke the deployed function.** This sends last month's report to every recipient
   (and to the binbash copy, if set): agree on it with the client first.
   ```bash
   aws lambda invoke --function-name <project>-management-cost-email-report \
     --cli-binary-format raw-in-base64-out --payload '{}' /dev/stdout
   ```
   The result shows the month and how many recipients it went to.
5. **Test the alarm.** An invalid month makes the function fail without sending anything:
   ```bash
   aws lambda invoke --function-name <project>-management-cost-email-report \
     --cli-binary-format raw-in-base64-out --payload '{"month": "bad"}' /dev/stdout
   ```
   Within about five minutes the alarm `<project>-management-cost-email-report-errors`
   goes to `ALARM` and notifies the monitoring topic. It returns to `OK` by itself.

From then on, the report goes out on the 5th of every month at 12:00 UTC.

## 6. Uninstall

From `client/management/us-east-1/cost-email-report`:

1. If the SES identity was imported in step 4 and something else still uses it, take it
   out of the state first, so the destroy keeps it (native `tofu`, with the layer's
   backend configuration):
   ```bash
   tofu state rm aws_sesv2_email_identity.domain 'aws_route53_record.dkim'
   ```
2. `leverage tofu destroy`. It removes the function, its log group, schedule, role, alarm,
   the SES identity and the DKIM records.
3. Delete the directory and its `infracost.yml` entry in a PR.
