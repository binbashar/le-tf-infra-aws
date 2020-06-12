.PHONY: help
SHELL                   := /bin/bash
MAKEFILE_IMPORT_ANSIBLE := ../../../@bin/makefiles/ansible/Makefile.ansible

#
# MAKE GIT DEFINITIONS
#
define MAKE_ANSIBLE
make \
-f ${MAKEFILE_IMPORT_ANSIBLE}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# ANSIBLE                                                      #
#==============================================================#
init-ansible-py: ## Install required ansible version
		${MAKE_ANSIBLE} init-ansible-py

#==============================================================#
# RCLONE                                                       #
#==============================================================#
apply: ## run rclone sync script
	bash rclone_gdrive_awss3_sync.sh rclone_bb_gdrive_awss3_sync

decrypt: ## Decrypt secrets via ansible-vault
	ansible-vault decrypt --output rclone.conf rclone.conf.enc

encrypt: ## Encrypt secrets via ansible-vault
	ansible-vault encrypt --output rclone.conf.enc rclone.conf \
  && rm -rf rclone.conf
