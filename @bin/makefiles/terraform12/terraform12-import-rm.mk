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
TF_PWD_CONFIG_DIR                := $(shell cd ../ && cd config && pwd)
TF_PWD_COMMON_CONFIG_DIR         := $(shell cd ../../ && cd config && pwd)
TF_VER                           := 0.12.28
TF_DOCKER_BACKEND_CONF_VARS_FILE := /config/backend.config
TF_DOCKER_ACCOUNT_CONF_VARS_FILE := /config/account.config
TF_DOCKER_COMMON_CONF_VARS_FILE  := /common-config/common.config
TF_DOCKER_ENTRYPOINT             := /usr/local/go/bin/terraform
TF_DOCKER_IMAGE                  := binbash/terraform-awscli

TF_IMPORT_RESOURCE                := "aws_organizations_organizational_unit.bbl_apps_devstg"
TF_IMPORT_RESOURCE_ID             := "ou-oz9d-yl3npduj"
TF_RM_RESOURCE                    := "aws_organizations_organizational_unit.bbl_apps_devstg"

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

help:
	@echo 'Available Commands:'
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":"}; { if ($$3 == "") { printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2 } else { printf " - \033[36m%-18s\033[0m %s\n", $$2, $$3 }}'

#==============================================================#
# TERRAFORM                                                    #
#==============================================================#
#
# Terraform Import & rm aux commands
#
import: ## terraform import resources - eg: make import TF_IMPORT_RESOURCE_LIST='${TF_IMPORT_RESOURCE_LIST_ARG}'
	REPOS=(${TF_IMPORT_RESOURCE_LIST});\
    OLDIFS=$$IFS;\
    IFS=',';\
    for i in "$${REPOS[@]}"; do\
        set -- $$i;\
		if [ "$$2" != "" ]; then\
			echo -----------------------;\
			echo $$1;\
			echo $$2;\
			echo -----------------------;\
			${TF_CMD_PREFIX} import \
				-var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} \
				-var-file=${TF_DOCKER_BASE_CONF_VARS_FILE} \
				-var-file=${TF_DOCKER_ACCOUNT_CONF_VARS_FILE} $$1 $$2;\
			echo -----------------------;\
			echo "TF SUCCESSFULLY IMPORTED $$1";\
			cd ..;\
			echo "";\
		fi;\
	done;\
	IFS=$$OLDIFS

state-rm: ## terraform rm resource from state - eg: make state-rm TF_RM_RESOURCE='${TF_RM_RESOURCE_ARG}'
	${TF_CMD_PREFIX} state rm ${TF_RM_RESOURCE}
