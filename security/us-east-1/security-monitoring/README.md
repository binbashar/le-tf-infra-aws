# Amazon GuardDuty

Organization-wide GuardDuty, managed from this account as the delegated administrator.
**Foundational threat detection only**: every optional protection plan (S3, EKS audit logs,
EBS malware, RDS, Lambda, Runtime Monitoring) is disabled, and none is auto-enabled.

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
```

## Notes about removing GuardDuty
Before removing it you need to disassociate all accounts via the AWS CLI or the AWS Console.

But even after that, you won't be able to remove it from this layer, instead you'll have to remove the administrator delegation that is set up in the management account. And then you'll need to remove the remaining resources on this layer.
