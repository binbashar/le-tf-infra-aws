.PHONY: help
SHELL := /bin/bash
LOCAL_OS_AWS_CONF_DIR := ~/.aws
LOCAL_OS_AWS_PROFILE := bb-dev-deploymaster
LOCAL_OS_AWS_REGION := us-east-1

TF_PWD_DIR := $(shell pwd)
TF_VER := 0.12.19
TF_PWD_CONT_DIR := "/go/src/project/"
TF_DOCKER_ENTRYPOINT := /usr/local/go/bin/terraform
TF_DOCKER_IMAGE := binbash/terraform-resources

#
# TERRAFORM
#
define TF_CMD_PREFIX
docker run --rm \
-v ${TF_PWD_DIR}:${TF_PWD_CONT_DIR}:rw \
--entrypoint=${TF_DOCKER_ENTRYPOINT} \
-it ${TF_DOCKER_IMAGE}:${TF_VER}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# TERRAFORM 												                           #
#==============================================================#
version: ## Show terraform version
	${TF_CMD_PREFIX} version

format: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${TF_CMD_PREFIX} fmt ${TF_PWD_CONT_DIR}

format-check: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${TF_CMD_PREFIX} fmt -check ${TF_PWD_CONT_DIR}

tflint: ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
	docker run --rm \
	-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws \
	-v ${TF_PWD_DIR}:/data \
	-t wata727/tflint:0.13.2

tflint-deep: ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
	docker run --rm \
	-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws \
	-v ${TF_PWD_DIR}:/data \
	-t wata727/tflint:0.13.2 --deep \
	--aws-profile=${LOCAL_OS_AWS_PROFILE} \
	--aws-creds-file=/root/.aws/credentials \
	--aws-region=${LOCAL_OS_AWS_REGION}

#==============================================================#
# CIRCLECI 													                           #
#==============================================================#
circleci-validate-config: ## Validate A CircleCI Config (https://circleci.com/docs/2.0/local-cli/)
	circleci config validate .circleci/config.yml
