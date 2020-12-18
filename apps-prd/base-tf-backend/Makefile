ENVIRONMENT   := apps-prd
AWS_ACCT_ID   := 802787198489

define TF_IMPORT_RESOURCE_LIST
"module.terraform_backend.aws_dynamodb_table.without_server_side_encryption[0]","${PROJECT_SHORT}-${ENVIRONMENT}-terraform-backend" \
"module.terraform_backend.aws_iam_policy.bucket_replication[0]","arn:aws:iam::${AWS_ACCT_ID}:policy/${PROJECT_SHORT}-${ENVIRONMENT}-terraform-backend-bucket-replication-module" \
"module.terraform_backend.aws_iam_role.bucket_replication[0]","${PROJECT_SHORT}-${ENVIRONMENT}-terraform-backend-bucket-replication-module" \
"module.terraform_backend.aws_s3_bucket.default","${PROJECT_SHORT}-${ENVIRONMENT}-terraform-backend" \
"module.terraform_backend.aws_s3_bucket_public_access_block.default","${PROJECT_SHORT}-${ENVIRONMENT}-terraform-backend" \
"module.terraform_backend.aws_s3_bucket.replication_bucket[0]","${PROJECT_SHORT}-${ENVIRONMENT}-terraform-backend-replica"
endef

define TF_RM_RESOURCE
"module.terraform_backend.aws_iam_role.bucket_replication[0]"
endef

-include ../../@bin/makefiles/terraform14/terraform14-mfa.mk
#
## This include should only be uncommented when importing tf resources is needed
## warning: when not commented the arguments declared in this makefile will have preference
## over any previous included makefile.
#
#-include ../../@bin/makefiles/terraform14/terraform14-import-rm-mfa.mk
