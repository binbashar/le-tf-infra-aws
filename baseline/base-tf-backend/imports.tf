# Import blocks for existing Terraform backend resources
# These imports are based on the plan.txt output showing resources to be created

# ===========================================
# APPS-DEVSTG ACCOUNT - US-EAST-1 REGION
# ===========================================
import {
  to = module.base_tf_backend["apps-devstg"].aws_dynamodb_table.without_server_side_encryption[0]
  id = "bb-apps-devstg-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket.default
  id = "bb-apps-devstg-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket.replication_bucket[0]
  id = "bb-apps-devstg-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_public_access_block.default
  id = "bb-apps-devstg-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-apps-devstg-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_versioning.default
  id = "bb-apps-devstg-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-apps-devstg-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-apps-devstg-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-apps-devstg-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_iam_role.bucket_replication[0]
  id = "bb-apps-devstg-terraform-backend-bucket-replication"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::523857393444:policy/bb-apps-devstg-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["apps-devstg"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-apps-devstg-terraform-backend-bucket-replication"
#}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_policy.default[0]
  id = "bb-apps-devstg-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-apps-devstg-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-devstg"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# APPS-PRD ACCOUNT - US-EAST-1 REGION
# ===========================================
import {
  to = module.base_tf_backend["apps-prd"].aws_dynamodb_table.without_server_side_encryption[0]
  id = "bb-apps-prd-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket.default
  id = "bb-apps-prd-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket.replication_bucket[0]
  id = "bb-apps-prd-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_public_access_block.default
  id = "bb-apps-prd-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-apps-prd-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_versioning.default
  id = "bb-apps-prd-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-apps-prd-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-apps-prd-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-apps-prd-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_iam_role.bucket_replication[0]
  id = "bb-apps-prd-terraform-backend-bucket-replication"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::802787198489:policy/bb-apps-prd-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["apps-prd"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-apps-prd-terraform-backend-bucket-replication"
#}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_policy.default[0]
  id = "bb-apps-prd-terraform-backend"
}

import {
  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-apps-prd-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["apps-prd"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# DATA-SCIENCE ACCOUNT - US-EAST-1 REGION
# ===========================================
import {
  to = module.base_tf_backend["data-science"].aws_dynamodb_table.without_server_side_encryption[0]
  id = "bb-data-science-terraform-backend"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket.default
  id = "bb-data-science-terraform-backend"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket.replication_bucket[0]
  id = "bb-data-science-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_public_access_block.default
  id = "bb-data-science-terraform-backend"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-data-science-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_versioning.default
  id = "bb-data-science-terraform-backend"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-data-science-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-data-science-terraform-backend"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-data-science-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["data-science"].aws_iam_role.bucket_replication[0]
  id = "bb-data-science-terraform-backend-bucket-replication"
}

import {
  to = module.base_tf_backend["data-science"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::905418344519:policy/bb-data-science-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["data-science"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-data-science-terraform-backend-role-policy-attachment"
#}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_policy.default[0]
  id = "bb-data-science-terraform-backend"
}

import {
  to = module.base_tf_backend["data-science"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-data-science-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["data-science"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# MANAGEMENT ACCOUNT - US-EAST-1 REGION
# ===========================================

# The account was re-named to management and the module enforce the dynamodb table's name
#import {
#  to = module.base_tf_backend["management"].aws_dynamodb_table.without_server_side_encryption[0]
#  id = "bb-root-terraform-backend"
#}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket.default
  id = "bb-root-terraform-backend"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket.replication_bucket[0]
  id = "bb-root-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_public_access_block.default
  id = "bb-root-terraform-backend"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-root-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_versioning.default
  id = "bb-root-terraform-backend"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-root-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-root-terraform-backend"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-root-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["management"].aws_iam_role.bucket_replication[0]
  id = "bb-root-terraform-backend-bucket-replication"
}

import {
  to = module.base_tf_backend["management"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::754065527950:policy/bb-root-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["management"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-root-terraform-backend-role-policy-attachment"
#}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_policy.default[0]
  id = "bb-root-terraform-backend"
}

import {
  to = module.base_tf_backend["management"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-root-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["management"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# NETWORK ACCOUNT - US-EAST-1 REGION
# ===========================================
import {
  to = module.base_tf_backend["network"].aws_dynamodb_table.without_server_side_encryption[0]
  id = "bb-network-terraform-backend"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket.default
  id = "bb-network-terraform-backend"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket.replication_bucket[0]
  id = "bb-network-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_public_access_block.default
  id = "bb-network-terraform-backend"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-network-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_versioning.default
  id = "bb-network-terraform-backend"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-network-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-network-terraform-backend"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-network-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["network"].aws_iam_role.bucket_replication[0]
  id = "bb-network-terraform-backend-bucket-replication"
}

import {
  to = module.base_tf_backend["network"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::822280187662:policy/bb-network-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["network"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-network-terraform-backend-role-policy-attachment"
#}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_policy.default[0]
  id = "bb-network-terraform-backend"
}

import {
  to = module.base_tf_backend["network"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-network-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["network"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# SECURITY ACCOUNT - US-EAST-1 REGION
# ===========================================
import {
  to = module.base_tf_backend["security"].aws_dynamodb_table.without_server_side_encryption[0]
  id = "bb-security-terraform-backend"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket.default
  id = "bb-security-terraform-backend"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket.replication_bucket[0]
  id = "bb-security-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_public_access_block.default
  id = "bb-security-terraform-backend"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-security-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_versioning.default
  id = "bb-security-terraform-backend"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-security-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-security-terraform-backend"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-security-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["security"].aws_iam_role.bucket_replication[0]
  id = "bb-security-terraform-backend-bucket-replication"
}

import {
  to = module.base_tf_backend["security"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::900980591242:policy/bb-security-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["security"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-security-terraform-backend-role-policy-attachment"
#}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_policy.default[0]
  id = "bb-security-terraform-backend"
}

import {
  to = module.base_tf_backend["security"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-security-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["security"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# SHARED ACCOUNT - US-EAST-1 REGION
# ===========================================
import {
  to = module.base_tf_backend["shared"].aws_dynamodb_table.without_server_side_encryption[0]
  id = "bb-shared-terraform-backend"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket.default
  id = "bb-shared-terraform-backend"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket.replication_bucket[0]
  id = "bb-shared-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_public_access_block.default
  id = "bb-shared-terraform-backend"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_public_access_block.replication_bucket[0]
  id = "bb-shared-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_versioning.default
  id = "bb-shared-terraform-backend"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_versioning.replication_bucket[0]
  id = "bb-shared-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_server_side_encryption_configuration.default
  id = "bb-shared-terraform-backend"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_server_side_encryption_configuration.replication_bucket[0]
  id = "bb-shared-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["shared"].aws_iam_role.bucket_replication[0]
  id = "bb-shared-terraform-backend-bucket-replication-module"
}

import {
  to = module.base_tf_backend["shared"].aws_iam_policy.bucket_replication[0]
  id = "arn:aws:iam::763606934258:policy/bb-shared-terraform-backend-bucket-replication"
}

#import {
#  to = module.base_tf_backend["shared"].aws_iam_policy_attachment.bucket_replication[0]
#  id = "bb-shared-terraform-backend-bucket-replication-module"
#}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_policy.default[0]
  id = "bb-shared-terraform-backend"
}

import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_policy.bucket_replication[0]
  id = "bb-shared-terraform-backend-replica"
}

import {
  to = module.base_tf_backend["shared"].time_sleep.wait_30_secs
  id = "30s,"
}

# ===========================================
# S3 BUCKET REPLICATION CONFIGURATION IMPORTS
# ===========================================

# Apps Dev/Staging Account
#import {
#  to = module.base_tf_backend["apps-devstg"].aws_s3_bucket_replication_configuration.this[0]
#  id = "bb-apps-devstg-terraform-backend"
#}
#
## Apps Production Account
#import {
#  to = module.base_tf_backend["apps-prd"].aws_s3_bucket_replication_configuration.this[0]
#  id = "bb-apps-prd-terraform-backend"
#}
#
## Data Science Account
#import {
#  to = module.base_tf_backend["data-science"].aws_s3_bucket_replication_configuration.this[0]
#  id = "bb-data-science-terraform-backend"
#}
#
## Management Account
#import {
#  to = module.base_tf_backend["management"].aws_s3_bucket_replication_configuration.this[0]
#  id = "bb-root-terraform-backend"
#}
#
## Network Account
#import {
#  to = module.base_tf_backend["network"].aws_s3_bucket_replication_configuration.this[0]
#  id = "bb-network-terraform-backend"
#}
#
## Security Account
#import {
#  for_each = local.accounts
#  to = module.base_tf_backend[each.key].aws_s3_bucket_replication_configuration.this[0]
#  id = "bb-${each.key}-terraform-backend"
#}

# Shared Account
import {
  to = module.base_tf_backend["shared"].aws_s3_bucket_replication_configuration.this[0]
  id = "bb-shared-terraform-backend"
}
