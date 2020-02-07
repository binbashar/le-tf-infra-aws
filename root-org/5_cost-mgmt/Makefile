.PHONY: help
SHELL := /bin/bash
MAKEFILE_IMPORT_TF := terraform11/Makefile.terraform11-cont

define MAKE_TF
make \
-f ../../@makefiles/${MAKEFILE_IMPORT_TF}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# TERRAFORM 												                           #
#==============================================================#
version: ## Show terraform version
	${MAKE_TF} version

init: ## Initialize terraform backend, plugins, and modules
	${MAKE_TF} init

plan: ## Preview terraform changes
	${MAKE_TF} plan

plan-detailed: ## Preview terraform changes with a more detailed output
	${MAKE_TF} plan -detailed-exitcode

apply: ## Make terraform apply any changes with dockerized binary
	${MAKE_TF} apply

output: ## Terraform output command is used to extract the value of an output variable from the state file.
	${MAKE_TF} output

destroy: ## Destroy all resources managed by terraform
	${MAKE_TF} destroy

format: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${MAKE_TF} fmt

force-unlock: ## Manually unlock the terraform state, eg: make ARGS="a94b0919-de5b-9b8f-4bdf-f2d7a3d47112" force-unlock
	${MAKE_TF} force-unlock

validate-tf-layout: ## Validate Terraform layout to make sure it's set up properly
	${MAKE_TF} validate-tf-layout
