# Amazon GuardDuty

Organization-wide GuardDuty, managed from this account as the delegated administrator.
**Foundational threat detection only**: every optional protection plan (S3, EKS audit logs,
EBS malware, RDS, Lambda, Runtime Monitoring) is disabled on the management and security
detectors, and none is auto-enabled in member accounts.

Auto-enable `NONE` does not turn off a plan a member account already has enabled. Before the
first apply, none of the accounts we could inspect had a GuardDuty detector (every account except
the three `workshop-genai-*` ones, which have no profile). The member checks below are what confirm
that every member is foundational-only, then and after any later change.

| Layer | What it does |
|---|---|
| `management/us-east-1/security-monitoring` | Management account detector (plans off) and delegation of the admin to this account |
| `security/us-east-1/security-monitoring` (this one) | Reads the detector AWS creates on delegation, keeps its plans off, auto-enables GuardDuty in **every** account (`ALL`, existing and new), adds the management account as a member, and posts findings to Slack |

## Apply order
1. `management/us-east-1/security-monitoring`
2. `security/us-east-1/security-monitoring`

Designating the delegated admin makes AWS enable GuardDuty in this account, so this layer
reads that detector (`data "aws_guardduty_detector"`) instead of creating it. Until step 1 is
applied, planning this layer fails with `reading this account's single GuardDuty Detector:
empty result`. AWS can take up to 24 hours to enable GuardDuty in every member account.

## Verify
```bash
DET=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
aws guardduty get-detector --detector-id $DET --query 'Features[?Status==`ENABLED`].Name'
aws guardduty describe-organization-configuration --detector-id $DET --query 'Features[?AutoEnable!=`NONE`].Name'
aws guardduty list-members --detector-id $DET --query 'Members[].[AccountId,RelationshipStatus]' --output text

# Members with any protection plan enabled, and accounts GuardDuty could not inspect.
# Expect both lists empty, per batch of up to 50 accounts.
aws guardduty list-members --detector-id $DET --query 'Members[].AccountId' --output text | xargs -n 50 \
  aws guardduty get-member-detectors --detector-id $DET \
    --query '{plans_enabled: MemberDataSourceConfigurations[?Features[?Status==`ENABLED`]].AccountId, unprocessed: UnprocessedAccounts}' \
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
