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

# uv run, not a bare python3: the scanner needs python-hcl2 >= 8.1, while this repo's
# own .venv pins 7.3.1 for the Leverage CLI -- so resolving the interpreter from PATH
# breaks precisely for contributors who followed the setup guide. --with-requirements
# builds the environment on demand; there is no venv to create or activate.
.PHONY: version-support
version-support: ## Check EKS/RDS versions against AWS support lifecycles
	@PYTHONPATH=scripts uv run --quiet \
		--with-requirements scripts/version_support/requirements.txt \
		python -m version_support --mode pr --root .

.PHONY: version-support-table
version-support-table: ## Regenerate docs/version-support/status.md
	@PYTHONPATH=scripts uv run --quiet \
		--with-requirements scripts/version_support/requirements.txt \
		python -m version_support --mode table --root .
