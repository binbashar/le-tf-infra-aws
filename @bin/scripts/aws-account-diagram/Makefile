.PHONY: build
SHELL             := /bin/bash
LOCAL_OS_USER_ID  := $(shell id -u)
LOCAL_OS_GROUP_ID := $(shell id -g)

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

dir-chmod: ## run chown in ./data to grant that the docker mounted dir has the right permissions
	@echo LOCAL_OS_USER_ID: ${LOCAL_OS_USER_ID}
	@echo LOCAL_OS_GROUP_ID: ${LOCAL_OS_GROUP_ID}
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./data

build: ## Build CloudMapper and AwsSecurtyViz docker images
	bash ./build/make_build.sh

apply-net: apply-net-cmd dir-chmod  ## Create HTML accessible diagram dashbord
apply-net-cmd:
	bash ./make_diagram_net.sh

apply-sg: apply-sg-cmd dir-chmod ## Create HTML accessible sg diagram dashbord
apply-sg-cmd:
	bash ./make_diagram_sg.sh

.PHONY: help
SHELL := /bin/bash

