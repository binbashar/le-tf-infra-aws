.PHONY: help

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

version: ## Show terraform versio
	terraform version

init: ## Initialize terraform backend, plugins, and modules"
	terraform init -backend-config=../config/backend.config

state_list: ## The terraform state list command is used to list resources within a Terraform state
	terraform state list

#state_remove: ## terraform state rm command is used to remove items from the Terraform state. Can remove single resources, single instances of a resource, entire modules, and more.
#	terraform state rm ""

plan: ## Preview terraform changes"
	terraform plan -var-file=../config/backend.config -var-file=../config/main.config

diff: ## Terraform plan with landscape
	terraform plan -var-file=../config/backend.config -var-file=../config/main.config | docker run -i --rm binbash/terraform-landscape

apply: ## Make terraform apply any changes"
	terraform apply -var-file=../config/backend.config -var-file=../config/main.config

destroy: ## Destroy all resources managed by terraform"
	terraform destroy -var-file=../config/backend.config -var-file=../config/main.config