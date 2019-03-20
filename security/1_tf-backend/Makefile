.PHONY: help

help:
	@echo "Help:"
	@echo "   -> Make sure you read readme.md before running this"
	@echo "   -> After that you can execute 'make run'"

version:
	terraform version

init:
	terraform init -backend-config=../config/backend.config

apply:
	terraform apply -var-file=../config/backend.config

destroy:
	terraform destroy -var-file=../config/backend.config

