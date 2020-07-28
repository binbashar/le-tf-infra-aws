#
# Enable encrypted EBS by default (HIPAA)
#
resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}

#
# Disable public access through ACLs or bucket policies to all buckets by default
#
resource "aws_s3_account_public_access_block" "main" {
  block_public_acls   = true
  block_public_policy = true
}
