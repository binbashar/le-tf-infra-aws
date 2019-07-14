.PHONY: help
SHELL := /bin/bash

# ANSIBLE VARS
ANSIBLE_SSH_HOST := jenkins.aws.binbash.com.ar
ANSIBLE_USER := ubuntu
ANSIBLE_SSH_KEY := ../keys/id_rsa
ANSIBLE_VAULT_PASSWORK_FILE := ./secrets/.vault_pass

# LETSENCRYPT VARS
LETSENCRYPT_DIR_PATH := /etc/letsencrypt/
LETSENCRYPT_DIR_PATH_CERTS := /etc/letsencrypt/archive/
LETSENCRYPT_DOMAIN := aws.binbash.com.ar
LETSENCRYPT_CERT_VER := $(shell sudo ls /etc/letsencrypt/archive/aws.binbash.com.ar |grep -Eo '[2-999]{1,3}.pem$$'|cut -d'.' -f1|sort|uniq|tail -1)

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

ansible-playbook: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml

ansible-playbook-multi-tag: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags common_tasks,letsencrypt

ansible-playbook-sec-users: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags security-users

ansible-playbook-containers: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags containers

ansible-playbook-jenkins: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags jenkins

ansible-playbook-jenkins-post-tasks: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags jenkins-post-tasks

ansible-playbook-jenkins-skip: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --skip-tags jenkins

ansible-playbook-nginx: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags nginx

ansible-playbook-letsencrypt: ## run ansible-playbook w/ vault password file and tags
	ansible-playbook --vault-password-file ${ANSIBLE_VAULT_PASSWORK_FILE} setup.yml --tags letsencrypt

bash-letsencrypt-pre-task-1: ## run letsencrypt wilcard cert 1st manual pre-req
	bash roles/binbash_inc.letsencrypt-wildcard-to-s3/files/letsencrypt_helper.sh

bash-letsencrypt-pre-task-2: ## push letsencrypt wilcard cert 1st manual pre-req to jenkins instance
	## pre-reqs: rename
	#sudo apt-get update && sudo apt-get install rename
	@echo LETSENCRYPT_CERT_VER: ${LETSENCRYPT_CERT_VER}
	sudo rename -f 's/${LETSENCRYPT_CERT_VER}.pem/1.pem/g' ${LETSENCRYPT_DIR_PATH_CERTS}${LETSENCRYPT_DOMAIN}/*
	ssh -i ${ANSIBLE_SSH_KEY} ${ANSIBLE_USER}@${ANSIBLE_SSH_HOST} 'sudo chown -R ${ANSIBLE_USER}:${ANSIBLE_USER} ${LETSENCRYPT_DIR_PATH}'
	sudo rsync -avzhOe  "ssh -i ${ANSIBLE_SSH_KEY}" --progress ${LETSENCRYPT_DIR_PATH} ${ANSIBLE_USER}@${ANSIBLE_SSH_HOST}:${LETSENCRYPT_DIR_PATH}
	ssh -i ${ANSIBLE_SSH_KEY} ${ANSIBLE_USER}@${ANSIBLE_SSH_HOST} 'sudo chown -R root:root ${LETSENCRYPT_DIR_PATH}'