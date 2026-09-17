.PHONY: help
SHELL         := /bin/bash
MAKEFILE_PATH := ./Makefile
MAKEFILES_DIR := ./@bin/makefiles
MAKEFILES_VER := v0.1.37

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# INITIALIZATION                                               #
#==============================================================#
init-makefiles: ## initialize makefiles
	rm -rf ${MAKEFILES_DIR}
	mkdir -p ${MAKEFILES_DIR}
	git clone https://github.com/binbashar/le-dev-makefiles.git ${MAKEFILES_DIR} -q
	cd ${MAKEFILES_DIR} && git checkout ${MAKEFILES_VER} -q

-include ${MAKEFILES_DIR}/circleci/circleci.mk
-include ${MAKEFILES_DIR}/release-mgmt/release.mk
-include ${MAKEFILES_DIR}/terraform1/terraform1-root-context.mk

infracost-breakdown: ## Infracost breakdown
	infracost breakdown \
		--config-file=./infracost.yml \
		--show-skipped

# The scanner is the one AWS-touching thing here that does not run through the leverage
# wrapper, and the wrapper is what exports AWS_CONFIG_FILE / AWS_SHARED_CREDENTIALS_FILE:
# ~/.aws/<project>/ is the only place this repo's SSO profiles exist. Without them boto3
# reads ~/.aws/config + ~/.aws/credentials instead and finds nothing -- and that does not
# fail the run, it degrades to "Unable to locate credentials", warns, and exits 0. A
# workstation whose default ~/.aws/config still carries a region is the worst case: the
# region resolves, so the run gets past client construction and dies only at the first
# call, which reads as a credentials problem rather than a wrong-config-file one. Region
# is the same trap from the other side -- boto3 reads AWS_DEFAULT_REGION and never
# AWS_REGION, whereas the AWS CLI honours both.
#
# Read out of the repo rather than hardcoded, so a renamed project or profile cannot
# leave a stale copy here (see CLAUDE.md on profile names being derived from the SSO
# permission set). Every value yields to one already exported, so an explicit
# `AWS_PROFILE=bb-shared-devops make version-support` still wins.
LEVERAGE_PROJECT := $(shell sed -nE 's/^[[:space:]]*project[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' config/common.tfvars 2>/dev/null | head -1)
LEVERAGE_PROJECT := $(or $(LEVERAGE_PROJECT),$(shell sed -nE 's/^PROJECT=//p' build.env 2>/dev/null | head -1))
LEVERAGE_PROFILE := $(shell sed -nE 's/^[[:space:]]*profile[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' apps-devstg/config/backend.tfvars 2>/dev/null | head -1)
LEVERAGE_REGION  := $(shell sed -nE 's/^[[:space:]]*region[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' apps-devstg/config/backend.tfvars 2>/dev/null | head -1)

# An empty AWS_PROFILE is not the same as an unset one -- botocore raises
# "The config profile () could not be found" -- hence :- throughout, and the $(if ...):
# if the profile cannot be read from the repo, leave the variable out and let the
# default credential chain answer.
VERSION_SUPPORT_AWS_ENV := \
	AWS_CONFIG_FILE="$${AWS_CONFIG_FILE:-$$HOME/.aws/$(LEVERAGE_PROJECT)/config}" \
	AWS_SHARED_CREDENTIALS_FILE="$${AWS_SHARED_CREDENTIALS_FILE:-$$HOME/.aws/$(LEVERAGE_PROJECT)/credentials}" \
	AWS_DEFAULT_REGION="$${AWS_DEFAULT_REGION:-$(or $(LEVERAGE_REGION),us-east-1)}" \
	$(if $(LEVERAGE_PROFILE),AWS_PROFILE="$${AWS_PROFILE:-$(LEVERAGE_PROFILE)}")

# uv run, not a bare python3: the scanner needs python-hcl2 >= 8.1, while this repo's
# own .venv pins 7.3.1 for the Leverage CLI -- so resolving the interpreter from PATH
# breaks precisely for contributors who followed the setup guide. --with-requirements
# builds the environment on demand; there is no venv to create or activate.
.PHONY: version-support
version-support: ## Check EKS/RDS versions against AWS support lifecycles
	@$(VERSION_SUPPORT_AWS_ENV) \
		PYTHONPATH=@bin/scripts uv run --quiet \
		--with-requirements @bin/scripts/version_support/requirements.txt \
		python -m version_support --mode pr --root .

.PHONY: version-support-table
version-support-table: ## Regenerate docs/version-support/status.md
	@$(VERSION_SUPPORT_AWS_ENV) \
		PYTHONPATH=@bin/scripts uv run --quiet \
		--with-requirements @bin/scripts/version_support/requirements.txt \
		python -m version_support --mode table --root .

# Stdlib only -- no requirements file and no AWS, deliberately unlike
# version-support, which needs python-hcl2 and live AWS lifecycle data.
# The test target uses uv because pytest is not a repo dependency.
.PHONY: prm-tags
prm-tags: ## Check every layer carries the PRM aws-apn-id tag
	@python3 @bin/scripts/prm_tags/check.py --root .

.PHONY: prm-tags-test
prm-tags-test: ## Run the PRM tag guardrail's own tests
	@uv run --quiet --with pytest pytest ./@bin/scripts/prm_tags/tests/ -q
