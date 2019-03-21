.PHONY: help

help:
	@echo "Usage Instructions:\n"
	@echo "  init: Initialize terraform backend, plugins, and modules"
	@echo "  plan: Preview terraform changes"
	@echo "  apply: Make terraform apply any changes"
	@echo "  destroy: Destroy all resources managed by terraform"
	@echo ""

version:
	terraform version

init:
	terraform init -backend-config=../config/backend.config

plan:
	terraform plan -var-file=../config/backend.config -var-file=../config/main.config

apply:
	terraform apply -var-file=../config/backend.config -var-file=../config/main.config

destroy:
	terraform destroy -var-file=../config/backend.config -var-file=../config/main.config