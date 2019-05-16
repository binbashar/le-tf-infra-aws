.PHONY: help

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

version: ## version: show terraform versio
	terraform version

init: ## init: Initialize terraform backend, plugins, and modules"
	terraform init -backend-config=../config/backend.config

apply: ## apply: Make terraform apply any changes"
	terraform apply -var-file=../config/backend.config

destroy: ## destroy: Destroy all resources managed by terraform"
	terraform destroy -var-file=../config/backend.config

