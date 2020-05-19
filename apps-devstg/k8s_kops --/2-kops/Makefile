.PHONY: help
SHELL                   := /bin/bash
MAKEFILE_IMPORT_TF      := terraform11/Makefile.terraform11-cont-subfolder
MAKEFILE_IMPORT_KOPS    := kops/Makefile.kops
MAKEFILE_IMPORT_KUBECTL := kubectl/Makefile.kubectl14


define MAKE_TF
make \
-f ../../../@bin/makefiles/${MAKEFILE_IMPORT_TF}
endef

define MAKE_KOPS
make \
-f ../../../@bin/makefiles/${MAKEFILE_IMPORT_KOPS}
endef

define MAKE_KUBECTL
make \
-f ../../../@bin/makefiles/${MAKEFILE_IMPORT_KUBECTL}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

#==============================================================#
# TERRAFORM                                                    #
#==============================================================#
version: ## Show terraform version
	${MAKE_TF} version

init: ## Initialize terraform backend, plugins, and modules
	${MAKE_TF} init

plan: ## Preview terraform changes
	${MAKE_TF} plan

plan-detailed: ## Preview terraform changes with a more detailed output
	${MAKE_TF} plan -detailed-exitcode

apply: ## Make terraform apply any changes with dockerized binary
	${MAKE_TF} apply

output: ## Terraform output command is used to extract the value of an output variable from the state file.
	${MAKE_TF} output

destroy: ## Destroy all resources managed by terraform
	${MAKE_TF} destroy

format: ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
	${MAKE_TF} fmt

force-unlock: ## Manually unlock the terraform state, eg: make ARGS="a94b0919-de5b-9b8f-4bdf-f2d7a3d47112" force-unlock
	${MAKE_TF} force-unlock

validate-tf-layout: ## Validate Terraform layout to make sure it's set up properly
	${MAKE_TF} validate-tf-layout

#==============================================================#
# KOPS                                                         #
#==============================================================#
cluster-get: ## Kops: get cluster info
	${MAKE_KOPS} cluster-get

cluster-update: ## Kops: update cluster state from cluster manifest
	${MAKE_KOPS} cluster-update

cluster-template: ## Kops: update the cluster template only
	${MAKE_KOPS} cluster-template

cluster-validate: ## Kops: validate cluster against the current state
	${MAKE_KOPS} cluster-validate

# Rolling Update: Cluster
#
cluster-rolling-update: ## Kops: perform a rolling update on the cluster -- only dry run, no changes will be applied
	${MAKE_KOPS} cluster-rolling-update

cluster-rolling-update-yes: ## Kops: perform a rolling update on the cluster
	${MAKE_KOPS} cluster-rolling-update-yes

cluster-rolling-update-yes-with-invervals: ## Kops: perform a rolling update on the cluster w/ intervals
	${MAKE_KOPS} cluster-rolling-update-yes-with-invervals

cluster-rolling-update-yes-force: ## Kops: perform a rolling update on the cluster (--force)
	${MAKE_KOPS} cluster-rolling-update-yes-force

cluster-rolling-update-yes-force-cloudonly: ## Kops: perform a rolling update on the cluster w/ --cloudonly -> without confirming progress with the k8s API
	${MAKE_KOPS} cluster-rolling-update-yes-force-cloudonly

# Rolling Update: Cluster Master Instance Group
#
cluster-rolling-update-yes-masters: ## Kops: perform a rolling update on the cluster masters
	${MAKE_KOPS} cluster-rolling-update-yes-masters

cluster-rolling-update-yes-force-masters: ## Kops: perform a rolling update on the cluster masters (--force)
	${MAKE_KOPS} cluster-rolling-update-yes-force-masters

# Rolling Update: Cluster Nodes Instance Groups
#
cluster-rolling-update-yes-nodes: ## Kops: perform a rolling update on the cluster nodes
	${MAKE_KOPS} cluster-rolling-update-yes-nodes

cluster-rolling-update-yes-force-nodes: ## Kops: perform a rolling update on the cluster nodes (--force)
	${MAKE_KOPS} cluster-rolling-update-yes-force-nodes

cluster-rolling-update-yes-nodes-memory-intensive: ## Kops: perform a rolling update on the cluster mem-intensive-nodes
	${MAKE_KOPS} cluster-rolling-update-yes-nodes-memory-intensive

cluster-rolling-update-yes-force-nodes-memory-intensive: ## Kops: perform a rolling update on the cluster mem-intensive-nodes (--force)
	${MAKE_KOPS} cluster-rolling-update-yes-force-nodes-memory-intensive

# Cluster Destroy
#
cluster-destroy: ## Kops: destroy cluster -- only dry run, no changes will be applied
	${MAKE_KOPS} cluster-destroy

cluster-destroy-yes: ## Kops: destroy cluster
	${MAKE_KOPS} cluster-destroy-yes

#==============================================================#
# KUBECTL                                                      #
#==============================================================#
test-run-kubectx-bash: ## docker run bash
	${MAKE_KUBECTL} test-run-kubectx-bash

test-run-kubectx-kubens-cmds: ## docker run kubectx and kubens --help to test
	${MAKE_KUBECTL} test-run-kubectx-kubens-cmds

test-run-kubectx-kubens: ## test-run: docker run with kubectx and kubens overrided entrypoints.
	${MAKE_KUBECTL} test-run-kubectx-kubens

test-run-kubectl: ## docker run kubectl commands
	${MAKE_KUBECTL} test-run-kubectl
