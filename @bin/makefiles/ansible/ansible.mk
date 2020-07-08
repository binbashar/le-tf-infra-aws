.PHONY: help
SHELL := /bin/bash

# ANSIBLE VARS
ANSIBLE_TAGS = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")

PY_PIP_VER := 20.1.1
PY_ANSIBLE_VER := 2.9.6

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# ANSIBLE	 												   #
#==============================================================#
init-ansible-py: ## Install required ansible version
		pip install --user --upgrade pip==${PY_PIP_VER}
		pip install --user -I ansible==${PY_ANSIBLE_VER}

init: ## Install required ansible roles
	ansible-galaxy install -f -r requirements.yml --roles-path ./roles/

apply: ## run ansible-playbook
	ansible-playbook setup.yml

apply-%: ## Provision only the given tags (e.g. make apply-security-users or make apply-openvpn-pritunl)
	ansible-playbook setup.yml --tags $(ANSIBLE_TAGS)

check: ## run ansible-playbook in Check Mode (“Dry Run”)
	ansible-playbook setup.yml --check

decrypt: ## Decrypt secrets.tf via ansible-vault
	ansible-vault decrypt --output ./group_vars/secrets.dec.yml ./group_vars/secrets.enc.yml

decrypt-string: ## Decrypt encrypted string via ansible-vault - eg: make ARG="your_encrypted_srting" decrypt-string
	bash ../@bin/scripts/ansible-vault-decrypt-str.sh ${ARG}

encrypt: ## Encrypt secrets.dec.tf via ansible-vault
	ansible-vault encrypt --output ./group_vars/secrets.enc.yml ./group_vars/secrets.dec.yml \
	&& rm -rf ./group_vars/secrets.dec.yml
