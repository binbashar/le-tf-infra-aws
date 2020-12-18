define TF_IMPORT_RESOURCE_LIST
"aws_s3_bucket.gdrive_backup","bb-shared-gdrive-backup"
endef

TF_RM_RESOURCE := "aws_s3_bucket.gdrive_bakcup"

-include ../../@bin/makefiles/terraform13/terraform13-mfa.mk
#
## This include should only be uncommented when importing tf resources is needed
## warning: when not commented the arguments declared in this makefile will have preference
## over any previous included makefile.
#
#-include ../../@bin/makefiles/terraform13/terraform13-import-rm-mfa.mk
