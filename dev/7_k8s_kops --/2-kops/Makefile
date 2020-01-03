.PHONY: help

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-40s\033[0m %s\n", $$1, $$2}'


init: ## Terraform: initialize backend, plugins and modules
	terraform init -backend-config="../../config/backend.config"

plan: ## Terraform: preview changes to the cluster resources managed by terraform
	terraform plan -var-file="../../config/backend.config" -var-file="../../config/base.config"

apply: ## Terraform: apply the changes to the cluster resources managed by terraform
	terraform apply -var-file="../../config/backend.config" -var-file="../../config/base.config"

destroy: ## Terraform: destroy all cluster resources managed by terraform
	terraform destroy -var-file="../../config/backend.config" -var-file="../../config/base.config"

cluster-get: ## Kops: get cluster info
	source cluster-config.sh && kops get $$CLUSTER_NAME \
		--state $$ClUSTER_STATE

cluster-update: ## Kops: update cluster state from cluster manifest
	./cluster-update.sh

cluster-template: ## Kops: update the cluster template only
	./cluster-template.sh

cluster-validate: ## Kops: validate cluster against the current state
	source cluster-config.sh && kops validate cluster \
		--state $$ClUSTER_STATE \
		--name $$CLUSTER_NAME

cluster-rolling-update: ## Kops: perform a rolling update on the cluster -- only dry run, no changes will be applied
	source cluster-config.sh && kops rolling-update cluster \
		--state $$ClUSTER_STATE \
		--name $$CLUSTER_NAME

cluster-rolling-update-yes: ## Kops: perform a rolling update on the cluster
	source cluster-config.sh && kops rolling-update cluster \
		--state $$ClUSTER_STATE \
		--name $$CLUSTER_NAME \
		--yes

cluster-rolling-update-yes-force-masters: ## Kops: perform a rolling update on the cluster masters
	source cluster-config.sh && kops rolling-update cluster \
		--state $$ClUSTER_STATE \
		--name $$CLUSTER_NAME \
		--instance-group-roles=Master \
		--yes \
		--force

cluster-destroy: ## Kops: destroy cluster
	source cluster-config.sh && kops delete cluster \
		--state $$ClUSTER_STATE \
		--name $$CLUSTER_NAME \
		--unregister

cluster-destroy-yes: ## Kops: destroy cluster
	source cluster-config.sh && kops delete cluster \
		--state $$ClUSTER_STATE \
		--name $$CLUSTER_NAME \
		--unregister \
		--yes
