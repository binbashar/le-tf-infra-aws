.PHONY: help
SHELL         := /bin/bash
MAKEFILES_DIR := ../../../@bin/makefiles

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

-include ${MAKEFILES_DIR}/ansible/ansible.mk

#==============================================================#
# RCLONE                                                       #
#==============================================================#
apply-rclone: ## run rclone sync script, remember to export your AWS credentials ENV vars
	bash rclone_gdrive_awss3_sync.sh rclone_bb_gdrive_awss3_sync
