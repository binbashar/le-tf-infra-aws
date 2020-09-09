.PHONY: help
SHELL := /bin/bash

PROJECT_SHORT                    := bb

LOCAL_OS_USER_ID                 := $(shell id -u)
LOCAL_OS_GROUP_ID                := $(shell id -g)
LOCAL_OS_SSH_DIR                 := ~/.ssh
LOCAL_OS_GIT_CONF_DIR            := ~/.gitconfig
LOCAL_OS_AWS_CONF_DIR            := ~/.aws/${PROJECT_SHORT}

TF_PWD_DIR                       := $(shell pwd)
TF_PWD_CONT_DIR                  := "/go/src/project/"
TF_PWD_CONFIG_DIR                := $(shell cd .. && cd config && pwd)
TF_PWD_COMMON_CONFIG_DIR         := $(shell cd ../.. && cd config && pwd)
TF_VER                           := 0.13.2
TF_DOCKER_BACKEND_CONF_VARS_FILE := /config/backend.config
TF_DOCKER_ACCOUNT_CONF_VARS_FILE := /config/account.config
TF_DOCKER_COMMON_CONF_VARS_FILE  := /common-config/common.config
TF_DOCKER_ENTRYPOINT             := /bin/terraform
TF_DOCKER_IMAGE                  := binbash/terraform-awscli-slim

define TF_CMD_PREFIX
docker run --rm \
-v ${TF_PWD_DIR}:${TF_PWD_CONT_DIR}:rw \
-v ${TF_PWD_CONFIG_DIR}:/config \
-v ${TF_PWD_COMMON_CONFIG_DIR}/common.config:${TF_DOCKER_COMMON_CONF_VARS_FILE} \
-v ${LOCAL_OS_SSH_DIR}:/root/.ssh \
-v ${LOCAL_OS_GIT_CONF_DIR}:/etc/gitconfig \
-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws/${PROJECT_SHORT} \
-e AWS_SHARED_CREDENTIALS_FILE=/root/.aws/${PROJECT_SHORT}/credentials \
-e AWS_CONFIG_FILE=/root/.aws/${PROJECT_SHORT}/config \
--entrypoint=${TF_DOCKER_ENTRYPOINT} \
-w ${TF_PWD_CONT_DIR} \
-it ${TF_DOCKER_IMAGE}:${TF_VER}
endef

define TF_CMD_BASH_PREFIX
docker run --rm \
-v ${TF_PWD_DIR}:${TF_PWD_CONT_DIR}:rw \
-v ${TF_PWD_CONFIG_DIR}:/config \
-v ${TF_PWD_COMMON_CONFIG_DIR}/common.config:${TF_DOCKER_COMMON_CONF_VARS_FILE} \
-v ${LOCAL_OS_SSH_DIR}:/root/.ssh \
-v ${LOCAL_OS_GIT_CONF_DIR}:/etc/gitconfig \
-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws/${PROJECT_SHORT} \
-e AWS_SHARED_CREDENTIALS_FILE=/root/.aws/${PROJECT_SHORT}/credentials \
-e AWS_CONFIG_FILE=/root/.aws/${PROJECT_SHORT}/config \
--entrypoint=bash \
-w ${TF_PWD_CONT_DIR} \
-it ${TF_DOCKER_IMAGE}:${TF_VER}
endef

help:
	@echo 'Available Commands:'
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":"}; { if ($$3 == "") { printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2 } else { printf " - \033[36m%-18s\033[0m %s\n", $$2, $$3 }}'

#==============================================================#
# TERRAFORM                                                    #
#==============================================================#
tf-dir-chmod: ## run chown in ./.terraform to gran that the docker mounted dir has the right permissions
	@echo LOCAL_OS_USER_ID: ${LOCAL_OS_USER_ID}
	@echo LOCAL_OS_GROUP_ID: ${LOCAL_OS_GROUP_ID}
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./.terraform

shell: ## Initialize terraform backend, plugins, and modules
	${TF_CMD_BASH_PREFIX}

version: ## Show terraform version
	docker run --rm \
	--entrypoint=${TF_DOCKER_ENTRYPOINT} \
	-t ${TF_DOCKER_IMAGE}:${TF_VER} version

init: init-cmd tf-dir-chmod ## Initialize terraform backend, plugins, and modules
init-cmd:
	${TF_CMD_PREFIX} init \
	-backend-config=${TF_DOCKER_BACKEND_CONF_VARS_FILE}

init-reconfigure: init-reconfigure-cmd tf-dir-chmod ## Initialize and reconfigure terraform backend, plugins, and modules
init-reconfigure-cmd:
	${TF_CMD_PREFIX} init \
	-reconfigure \
	-backend-config=${TF_DOCKER_BACKEND_CONF_VARS_FILE}

plan: ## Preview terraform changes
	${TF_CMD_PREFIX} plan \
	-var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} \
	-var-file=${TF_DOCKER_COMMON_CONF_VARS_FILE} \
	-var-file=${TF_DOCKER_ACCOUNT_CONF_VARS_FILE}

plan-detailed: ## Preview terraform changes with a more detailed output
	${TF_CMD_PREFIX} plan -detailed-exitcode \
	 -var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} \
	 -var-file=${TF_DOCKER_COMMON_CONF_VARS_FILE} \
	 -var-file=${TF_DOCKER_ACCOUNT_CONF_VARS_FILE}

apply: apply-cmd tf-dir-chmod ## Make terraform apply any changes with dockerized binary
apply-cmd:
	${TF_CMD_PREFIX} apply \
	-var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} \
	-var-file=${TF_DOCKER_COMMON_CONF_VARS_FILE} \
	-var-file=${TF_DOCKER_ACCOUNT_CONF_VARS_FILE}

output: ## Terraform output command is used to extract the value of an output variable from the state file.
	${TF_CMD_PREFIX} output

destroy: ## Destroy all resources managed by terraform
	${TF_CMD_PREFIX} destroy \
	-var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} \
	-var-file=${TF_DOCKER_COMMON_CONF_VARS_FILE} \
	-var-file=${TF_DOCKER_ACCOUNT_CONF_VARS_FILE}

format: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${TF_CMD_PREFIX} fmt -recursive

format-check: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${TF_CMD_PREFIX} fmt -check
    # Consider adding -recursive after everything has been migrated to tf-0.12
	# (should exclude dev/8_k8s_kops/2-kops folder since it's not possible to migrate to
	# tf-0.12 yet
	# ${TF_CMD_PREFIX} fmt -recursive -check ${TF_PWD_CONT_DIR}

tflint: ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
	docker run --rm \
	-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws \
	-v ${TF_PWD_DIR}:/data \
	-t wata727/tflint:0.14.0

tflint-deep: ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
	docker run --rm \
	-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws \
	-v ${TF_PWD_DIR}:/data \
	-t wata727/tflint:0.14.0 --deep \
	--aws-profile=${LOCAL_OS_AWS_PROFILE} \
	--aws-creds-file=/root/.aws/credentials \
	--aws-region=${LOCAL_OS_AWS_REGION}

force-unlock: ## Manually unlock the terraform state, eg: make ARGS="a94b0919-de5b-9b8f-4bdf-f2d7a3d47112" force-unlock
	${TF_CMD_PREFIX} force-unlock ${ARGS}

decrypt: ## Decrypt secrets.tf via ansible-vault
	ansible-vault decrypt --output secrets.dec.tf secrets.enc

encrypt: ## Encrypt secrets.dec.tf via ansible-vault
	ansible-vault encrypt --output secrets.enc secrets.dec.tf \
  && rm -rf secrets.dec.tf

validate-tf-layout: ## Validate Terraform layout to make sure it's set up properly
	../../@bin/scripts/validate-terraform-layout.sh

cost-estimate-plan: ## Terraform plan output compatible with https://terraform-cost-estimation.com/
	curl -sLO https://raw.githubusercontent.com/antonbabenko/terraform-cost-estimation/master/terraform.jq
	${TF_CMD_PREFIX} plan -out=plan.tfplan \
	 -var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} \
	 -var-file=${TF_DOCKER_COMMON_CONF_VARS_FILE} \
	 -var-file=${TF_DOCKER_ACCOUNT_CONF_VARS_FILE}
	${TF_CMD_PREFIX} show -json plan.tfplan > plan.json
	@echo ----------------------------------------------------------------------
	cat plan.json \
	| curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
	@ #| jq -cf terraform.jq | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/ # TODO: Fix jq errorrs
	@echo ''
	@echo ----------------------------------------------------------------------
	@rm -rf terraform.jq plan.tfplan plan.json

cost-estimate-state: ## Terraform state output compatible with https://terraform-cost-estimation.com/
	curl -sLO https://raw.githubusercontent.com/antonbabenko/terraform-cost-estimation/master/terraform.jq
	${TF_CMD_PREFIX} state pull > state.json
	@echo ----------------------------------------------------------------------
	cat state.json \
	| curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
	@ #| jq -cf terraform.jq | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/ # TODO: Fix jq errorrs
	@echo ''
	@echo ----------------------------------------------------------------------
	@rm -rf terraform.jq state.json
