.PHONY: help
SHELL := /bin/bash

LOCAL_OS_USER := $(shell whoami)
LOCAL_OS_SSH_DIR := ~/.ssh
LOCAL_OS_GIT_CONF_DIR := ~/.gitconfig
LOCAL_OS_AWS_CONF_DIR := ~/.aws

TF_PWD_DIR := $(shell pwd)
TF_PWD_CONT_DIR := "/go/src/project/"
TF_PWD_CONFIG_DIR := $(shell cd .. && cd config && pwd)
TF_VER := 0.12.18
TF_DOCKER_BACKEND_CONF_VARS_FILE := /config/backend.config
TF_DOCKER_MAIN_CONF_VARS_FILE := /config/main.config
TF_DOCKER_ENTRYPOINT := /usr/local/go/bin/terraform
TF_DOCKER_IMAGE := binbash/terraform-resources

define TF_CMD_PREFIX
docker run --rm \
-v ${TF_PWD_DIR}:${TF_PWD_CONT_DIR}:rw \
-v ${TF_PWD_CONFIG_DIR}:/config \
-v ${LOCAL_OS_SSH_DIR}:/root/.ssh \
-v ${LOCAL_OS_GIT_CONF_DIR}:/etc/gitconfig \
-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws \
--entrypoint=${TF_DOCKER_ENTRYPOINT} \
-it ${TF_DOCKER_IMAGE}:${TF_VER}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

tf-dir-chmod: ## run chown in ./.terraform to gran that the docker mounted dir has the right permissions
	@echo LOCAL_OS_USER: ${LOCAL_OS_USER}
	sudo chown -R ${LOCAL_OS_USER}:${LOCAL_OS_USER} ./.terraform

version: ## Show terraform version
	docker run --rm \
	--entrypoint=${TF_DOCKER_ENTRYPOINT} \
	-t ${TF_DOCKER_IMAGE}:${TF_VER} version

init: init-cmd tf-dir-chmod ## Initialize terraform backend, plugins, and modules
init-cmd:
	${TF_CMD_PREFIX} init -backend-config=${TF_DOCKER_BACKEND_CONF_VARS_FILE} ${TF_PWD_CONT_DIR}

apply: apply-cmd tf-dir-chmod ## Make terraform apply any changes
apply-cmd:
	${TF_CMD_PREFIX} apply -var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} ${TF_PWD_CONT_DIR}

destroy: ## Destroy all resources managed by terraform
	${TF_CMD_PREFIX} destroy -var-file=${TF_DOCKER_BACKEND_CONF_VARS_FILE} ${TF_PWD_CONT_DIR}

