.PHONY: help

help:
	@echo "Help:"
	@echo "   -> Important: make sure you read readme.md"
	@echo ""
	@echo "Available Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

init: ## Initialize terraform backend, modules and plugins
	terraform12 init -backend-config="../../config/backend.config"

plan: ## Review any changes via terraform before actually applying them
	terraform12 plan -var-file="../../config/backend.config" -var-file="../../config/base.config" -var-file="../../config/extra.config"

apply: ## Apply your changes via terraform
	terraform12 apply -var-file="../../config/backend.config" -var-file="../../config/base.config" -var-file="../../config/extra.config"

destroy: ## Destroy terraform managed resources
	terraform12 destroy -var-file="../../config/backend.config" -var-file="../../config/base.config" -var-file="../../config/extra.config"

output: ## Show terraform outputs
	terraform12 output
