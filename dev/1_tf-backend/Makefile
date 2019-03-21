.PHONY: help

help:
	@echo "Help:"
	@echo "   -> Make sure you read readme.md before running this"
	@echo "   -> After that you can execute 'make run'"

init:
	terraform init -backend-config=../config/backend.config

apply:
	terraform apply -var-file=../config/backend.config
