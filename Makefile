.PHONY: help
PWD := $(shell pwd)

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

version: ## Show terraform version
	terraform version

format: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	terraform fmt

lint: ## lint: TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan.
	docker run --rm -v ${PWD}:/data -t wata727/tflint --deep