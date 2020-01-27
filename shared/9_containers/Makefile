.PHONY: help

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

version: ## Show terraform versio
	terraform version

init: ## Initialize terraform backend, plugins, and modules"
	terraform init -backend-config=../config/backend.config

plan: ## Preview terraform changes
	terraform plan -var-file=../config/backend.config -var-file=../config/main.config

diff: ## Terraform plan with landscape
	terraform plan -var-file=../config/backend.config -var-file=../config/main.config | docker run -i --rm binbash/terraform-landscape

apply: ## Make terraform apply any changes"
	terraform apply -var-file="..${TF_DOCKER_BACKEND_CONF_VARS_FILE}" -var-file="..${TF_DOCKER_MAIN_CONF_VARS_FILE}"

destroy: ## Destroy all resources managed by terraform
	terraform destroy -var-file=../config/backend.config -var-file=../config/main.config