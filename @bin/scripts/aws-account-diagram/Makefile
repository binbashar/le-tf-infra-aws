.PHONY: build
SHELL         := /bin/bash

LOCAL_OS_USER := $(shell whoami)

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

build: ## Build CloudMapper and AwsSecurtyViz docker images
	bash ./build/make_build.sh

apply: ## Create HTML accessible diagram dashbord
	bash ./make_diagram.sh
