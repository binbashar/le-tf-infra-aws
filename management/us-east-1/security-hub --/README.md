# AWS Security Hub

Enable [AWS Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html) with the security standards designated as default:
- AWS Foundational Security Best Practices v1.0.0
- CIS AWS Foundations Benchmark v1.2.0

## For Single account

If you are running a single AWS account, use this in such account:

```hcl
resource "aws_securityhub_account" "default" {
  enable_default_standards  = true
  auto_enable_controls      = true
  control_finding_generator = "SECURITY_CONTROL"
}
```


## For AWS Organizations

When running Organizations, follow these steps:

1. Delegate the Security Hub management to an account other than `management`.

```hcl
resource "aws_securityhub_organization_admin_account" "main" {
  admin_account_id = var.accounts.security.id
}
```

2. Then apply [this layer]("../../../security/us-east-1/security-hub%20--/") to the chosen account.

Note: It is recommended that the delegated account not be the `management` account. It is advised to use the `security` account as the delegated admin account.

## Full Destroy

If you want to disable Security Hub and you run  `leverage terraform destroy`, you might notice that Security Hub is still active and collecting findings from all accounts within your organization. To fully disable Security Hub, follow these steps:

1- Add the following blocks to your Terraform configuration:

```hcl
provider "aws" {
  alias = "security"
  region  = var.region
  profile = "${var.project}-security-devops"
}

resource "aws_securityhub_account" "security" {
  provider                 = aws.security
  enable_default_standards = false
}
```

(Note this assumes you are using `security` account for Security Hub, change it as per your needs)

2- Import the Security Hub account resource with the following command::

`leverage tf import aws_securityhub_account.security  $SECURITY_ACCOUNT_ID`

3- Finally, destroy the Terraform-managed infrastructure:
`leverage tf destroy`

For further reading, you can visit https://dev.to/aws-builders/how-to-manage-aws-security-hub-in-aws-organizations-using-terraform-5gl4
