PROJECT_SHORT := bb
ENVIRONEMT    := root
AWS_ACCT_ID   := 754065527950

define TF_IMPORT_RESOURCE_LIST_ARG
"module.terraform_backend.aws_dynamodb_table.without_server_side_encryption[0]","${PROJECT_SHORT}-${ENVIRONEMT}-terraform-backend" \
"module.terraform_backend.aws_iam_policy.bucket_replication[0]","arn:aws:iam::${AWS_ACCT_ID}:policy/${PROJECT_SHORT}-${ENVIRONEMT}-terraform-backend-bucket-replication-module" \
"module.terraform_backend.aws_iam_role.bucket_replication[0]","${PROJECT_SHORT}-${ENVIRONEMT}-terraform-backend-bucket-replication-module" \
"module.terraform_backend.aws_s3_bucket.default","${PROJECT_SHORT}-${ENVIRONEMT}-terraform-backend" \
"module.terraform_backend.aws_s3_bucket_public_access_block.default","${PROJECT_SHORT}-${ENVIRONEMT}-terraform-backend" \
"module.terraform_backend.aws_s3_bucket.replication_bucket[0]","${PROJECT_SHORT}-${ENVIRONEMT}-terraform-backend-replica"
endef

define TF_RM_RESOURCE_ARG
"module.terraform_backend.aws_iam_role.bucket_replication[0]"
endef

-include ../../@bin/makefiles/terraform13/terraform13.mk
-include ../../@bin/makefiles/terraform13/terraform13-import-rm.mk
