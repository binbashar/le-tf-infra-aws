.PHONY: help

help:
	terraform version

init:
	terraform init -backend-config=../config/backend.config

plan:
	terraform plan -var-file=../config/backend.config -var-file=../config/main.config

apply:
	terraform apply -var-file=../config/backend.config -var-file=../config/main.config

destroy:
	terraform destroy -var-file=../config/backend.config -var-file=../config/main.config