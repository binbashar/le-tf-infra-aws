.PHONY: help
SHELL						:= /bin/bash
MAKEFILE_IMPORT_TF			:= terraform12/Makefile.terraform12-cont
MAKEFILE_IMPORT_CIRCLECI 	:= circleci/Makefile.circleci


define MAKE_TF
make \
-f ./@bin/makefiles/${MAKEFILE_IMPORT_TF}
endef
define MAKE_CIRCLECI
make \
-f ./@bin/makefiles/${MAKEFILE_IMPORT_CIRCLECI}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# TERRAFORM                                                    #
#==============================================================#
version: ## Show terraform version
	${MAKE_TF} version

format: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${MAKE_TF} format

format-check: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${MAKE_TF} format-check

tflint: ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
	${MAKE_TF} tflint

tflint-deep: ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
	${MAKE_TF} tflint-deep

#==============================================================#
# CIRCLECI                                                     #
#==============================================================#
circleci-validate-config: ## Validate A CircleCI Config (https://circleci.com/docs/2.0/local-cli/)
	${MAKE_CIRCLECI} circleci-validate-config

#==============================================================#
# DOCUMENTATION                                                #
#==============================================================#
docs-local-prereqs: ## Install local mkdocs pre-requisites
	pip install mkdocs
	pip install pymdown-extensions
	pip install mkdocs-material-extensions
	pip install mkdocs-awesome-pages-plugin

docs-deploy-gh: ## deploy to Github pages
	mkdocs gh-deploy --config-file mkdocs.yml --theme material --clean

docs-live: ## Build and launch a local copy of the documentation website in http://localhost:3000
	@docker run --rm -it \
		-p 8000:8000 \
		-v ${PWD}:/docs \
		squidfunk/mkdocs-material:5.2.3

docs-check-dead-links: ## Check if the documentation contains dead links.
	@docker run -t \
	  -v $$PWD:/tmp aledbf/awesome_bot:0.1 \
	  --allow-dupe \
	  --allow-redirect $(shell find $$PWD -mindepth 1 -name "*.md" -printf '%P\n' | grep -v vendor | grep -v Changelog.md)