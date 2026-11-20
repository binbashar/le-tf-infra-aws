# Amazon GuardDuty

Organization-wide GuardDuty, managed from this account as the delegated administrator.
**Foundational threat detection only**: every optional protection plan (S3, EKS audit logs,
EBS malware, RDS, Lambda, Runtime Monitoring) is disabled on the management and security
detectors, and none is auto-enabled in member accounts.

Auto-enable `NONE` does not turn off a plan a member account already has enabled. On the first
rollout, four accounts with an earlier GuardDuty history (network and the three `workshop-genai-*`)
were enrolled with S3 Protection on. So this layer also disables every plan on every member
account in `var.accounts` (`aws_guardduty_member_detector_feature`), and re-asserts it on each apply.
The member checks below confirm that every member is foundational-only.

| Layer | What it does |
|---|---|
| `management/us-east-1/security-monitoring` | Management account detector (plans off) and delegation of the admin to this account |
| `security/us-east-1/security-monitoring` (this one) | Reads the detector AWS creates on delegation, keeps its plans off, auto-enables GuardDuty in **every** account (`ALL`, existing and new), disables every plan on each member in `var.accounts`, adds the management account as a member, and posts findings to Slack |

## Apply order
1. `management/us-east-1/security-monitoring`
2. `security/us-east-1/security-monitoring`

Designating the delegated admin makes AWS enable GuardDuty in this account, so this layer
reads that detector (`data "aws_guardduty_detector"`) instead of creating it. Until step 1 is
applied, planning this layer fails with `reading this account's single GuardDuty Detector:
empty result`. AWS can take up to 24 hours to enable GuardDuty in every member account.

**Adding an account to `var.accounts`.** The layer also disables every plan on each member
(`aws_guardduty_member_detector_feature`), which only works once the account is a member. AWS
enrolls a new organization account within up to 24 hours. An apply in that window fails for that
account's features (the account is not a member yet). Re-run `leverage tofu apply` once
`aws guardduty list-members --detector-id $DET` shows the account as `Enabled`.

## Verify
```bash
DET=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
# Protection plans enabled on this detector (expect []). The foundational sources
# CLOUD_TRAIL, DNS_LOGS and FLOW_LOGS always report ENABLED, so they are excluded.
aws guardduty get-detector --detector-id $DET --query 'Features[?Status==`ENABLED` && !contains([`CLOUD_TRAIL`,`DNS_LOGS`,`FLOW_LOGS`], Name)].Name'
aws guardduty describe-organization-configuration --detector-id $DET --query 'Features[?AutoEnable!=`NONE`].Name'
aws guardduty list-members --detector-id $DET --query 'Members[].[AccountId,RelationshipStatus]' --output text

# Members with any protection plan enabled, and accounts GuardDuty could not inspect.
# Expect both lists empty, per batch of up to 50 accounts.
aws guardduty list-members --detector-id $DET --query 'Members[].AccountId' --output text | xargs -n 50 \
  aws guardduty get-member-detectors --detector-id $DET \
    --query '{plans_enabled: MemberDataSourceConfigurations[?Features[?Status==`ENABLED` && !contains([`CLOUD_TRAIL`,`DNS_LOGS`,`FLOW_LOGS`], Name)]].AccountId, unprocessed: UnprocessedAccounts}' \
    --account-ids

# Every active organization account is an enabled member. Expect only the security account
# (the delegated admin) in the output. The account list needs a management-account profile.
comm -23 \
  <(aws organizations list-accounts --profile <MANAGEMENT_PROFILE> \
      --query 'Accounts[?State==`ACTIVE`].Id' --output text | tr '\t' '\n' | sort) \
  <(aws guardduty list-members --detector-id $DET \
      --query 'Members[?RelationshipStatus==`Enabled`].AccountId' --output text | tr '\t' '\n' | sort)

# Findings reach Slack: then confirm the sample finding arrives in the security channel
aws guardduty create-sample-findings --detector-id $DET --finding-types Recon:EC2/PortProbeUnprotectedPort
```

To turn a plan back off on a member, from this account:
```bash
aws guardduty update-member-detectors --detector-id $DET --account-ids <MEMBER_ACCOUNT_ID> \
  --features Name=S3_DATA_EVENTS,Status=DISABLED
```

## Removing GuardDuty
Order matters; AWS rejects the steps out of sequence.
1. Set `auto_enable_organization_members` to `NONE` here and apply: while it is `ALL`, AWS
   does not allow member accounts to be disassociated.
2. Disassociate and delete every member (`aws guardduty disassociate-members` then
   `aws guardduty delete-members`, with all member account IDs), including the management account.
3. Destroy `management/us-east-1/security-monitoring` (removes the delegated admin and the
   management detector).
4. Destroy this layer. The detector here is a data source, so it is left behind: delete it with
   `aws guardduty delete-detector` if GuardDuty should be fully off in this account.
