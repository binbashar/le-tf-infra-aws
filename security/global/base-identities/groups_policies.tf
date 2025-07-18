#
# Policies attached to Groups
#

#
# Policy: Assume DevOps Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_devops_role" {
  name        = "assume_devops_role"
  description = "Allow assume DevOps role in member accounts"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::${var.accounts.shared.id}:role/DevOps",
                "arn:aws:iam::${var.accounts.network.id}:role/DevOps",
                "arn:aws:iam::${var.accounts.security.id}:role/DevOps",
                "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DevOps",
                "arn:aws:iam::${var.accounts.apps-prd.id}:role/DevOps"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume Admin Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_admin_role" {
  name        = "assume_admin_role"
  description = "Allow assume Admin role in member accounts"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::${var.accounts.shared.id}:role/Admin",
                "arn:aws:iam::${var.accounts.network.id}:role/Admin",
                "arn:aws:iam::${var.accounts.security.id}:role/Admin",
                "arn:aws:iam::${var.accounts.apps-devstg.id}:role/Admin",
                "arn:aws:iam::${var.accounts.apps-prd.id}:role/Admin"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume DeployMaster Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_deploymaster_role" {
  name        = "assume_deploymaster_role"
  description = "Allow assume DeployMaster role in member accounts"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::${var.accounts.shared.id}:role/DeployMaster",
                "arn:aws:iam::${var.accounts.security.id}:role/DeployMaster",
                "arn:aws:iam::${var.accounts.network.id}:role/DeployMaster",
                "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DeployMaster",
                "arn:aws:iam::${var.accounts.apps-prd.id}:role/DeployMaster",
                "arn:aws:iam::${var.accounts.data-science.id}:role/DeployMaster",
                "arn:aws:iam::${var.accounts.management.id}:role/DeployMaster"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume Auditor Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_auditor_role" {
  name        = "assume_auditor_role"
  description = "Allow assume Auditor role in member accounts"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::${var.accounts.shared.id}:role/Auditor",
                "arn:aws:iam::${var.accounts.network.id}:role/Auditor",
                "arn:aws:iam::${var.accounts.security.id}:role/Auditor",
                "arn:aws:iam::${var.accounts.apps-devstg.id}:role/Auditor",
                "arn:aws:iam::${var.accounts.apps-prd.id}:role/Auditor"
            ]
        }
    ]
}
EOF
}

#
# Policy: Assume Finops Role (Cross-Org Accounts)
#
resource "aws_iam_policy" "assume_finops_role" {
  name        = "assume_finops_role"
  description = "Allow assume FinOps role in member accounts"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::${var.accounts.shared.id}:role/FinOps",
                "arn:aws:iam::${var.accounts.network.id}:role/FinOps",
                "arn:aws:iam::${var.accounts.apps-devstg.id}:role/FinOps",
                "arn:aws:iam::${var.accounts.apps-prd.id}:role/FinOps"
            ]
        }
    ]
}
EOF
}

#
# Policy: Allow s3_tx_reporter Group (S3 Cross-Org Permissions)
# Uncomment if you like to deploy and test /apps-devtg/storage/bucket-demo-files layer
#
/*data "aws_iam_policy_document" "s3_demo_put_object" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      "${data.terraform_remote_state.apps-devstg-storage-bucket-demo-files.outputs.s3_bucket_demo_files_arn}/",
      "${data.terraform_remote_state.apps-devstg-storage-bucket-demo-files.outputs.s3_bucket_demo_files_arn}*/ /*"
    ]
  }

  */ /*
  #
  # The actions in your policy do not support resource-level permissions and require you to choose All resources
  # so the users will be able to list your AWS Org Buckets which is STRONGLY DISCOURAGED!
  #
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = [
      "*",
    ]
  }
  */ /*

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*"
    ]
    resources = [
      data.terraform_remote_state.apps-devstg-keys.outputs.aws_kms_key_arn
    ]
  }
}*/

#
# Policy: Restricted access to IAM to allow self-management without exposing other users
#
resource "aws_iam_policy" "restricted_iam_self_management" {
  name        = "restricted_iam_self_management"
  description = "Allow IAM users to manage their own credentials"
  policy      = data.aws_iam_policy_document.restricted_iam_self_management.json
}
data "aws_iam_policy_document" "restricted_iam_self_management" {
  statement {
    sid    = "AllowSelfManagement"
    effect = "Allow"
    actions = [
      "iam:UploadSigningCertificate",
      "iam:UploadSSHPublicKey",
      "iam:UpdateUser",
      "iam:UpdateLoginProfile",
      "iam:UpdateAccessKey",
      "iam:ResyncMFADevice",
      "iam:List*",
      "iam:Get*",
      "iam:GenerateServiceLastAccessedDetails",
      "iam:GenerateCredentialReport",
      "iam:EnableMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:DeleteLoginProfile",
      "iam:DeleteAccessKey",
      "iam:CreateVirtualMFADevice",
      "iam:CreateLoginProfile",
      "iam:CreateAccessKey",
      "iam:ChangePassword"
    ]
    resources = [
      "arn:aws:iam::${var.accounts.security.id}:user/*/$${aws:username}",
      "arn:aws:iam::${var.accounts.security.id}:user/$${aws:username}",
      "arn:aws:iam::${var.accounts.security.id}:mfa/$${aws:username}"
    ]
  }

  statement {
    sid    = "AllowDeactivateMFADevice"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice"
    ]
    resources = [
      "arn:aws:iam::${var.accounts.security.id}:user/*/$${aws:username}",
      "arn:aws:iam::${var.accounts.security.id}:user/$${aws:username}",
      "arn:aws:iam::${var.accounts.security.id}:mfa/$${aws:username}"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = ["3600"]
    }
  }
}
