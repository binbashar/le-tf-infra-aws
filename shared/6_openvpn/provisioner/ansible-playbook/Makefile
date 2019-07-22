.PHONY: help
SHELL := /bin/bash

# ANSIBLE VARS
ANSIBLE_SSH_HOST := vpn.binbash.com.ar
ANSIBLE_USER := ubuntu
ANSIBLE_SSH_KEY := ../keys/id_rsa
ANSIBLE_VAULT_PASSWORK_FILE := ./secrets/.vault_pass

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

ansible-playbook: ## run ansible-playbook w/ vault password file
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml

ansible-playbook-multi-tag: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags common_tasks,security-users

ansible-playbook-sec-users: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags security-users

ansible-playbook-pritunl: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags openvpn-pritunl