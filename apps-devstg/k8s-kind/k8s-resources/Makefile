.PHONY: help

LOCAL_IP = $(shell ifconfig \
		| grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' \
		| grep -Eo '([0-9]*\.){3}[0-9]*' \
		| grep -v '127.0.0.1')

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z%_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

create: ## Create a cluster
	# Create a kind config file using your LAN IP...
	@echo $(LOCAL_IP) \
		| xargs -I '{}' sed s/\{SERVER_ADDR\}/{}/ kind/config.yaml.example \
		> kind/config.yaml
	
	# Create a kind cluster using the generated config file...
	kind create cluster --name kind --config=kind/config.yaml

ls: list
list: ## List all clusters
	kind get clusters

delete: ## Delete the cluster
	kind delete cluster --name kind

tfvars: ## Create/update terraform.tfvars file with cluster auth data
	@kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}' | xargs -0 printf "kubernetes_host=\"%s\"\n" > terraform.tfvars
	@kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | xargs -0 printf "kubernetes_cluster_ca_certificate=\"%s\"\n" >> terraform.tfvars
	@kubectl config view --raw --minify --flatten --output='jsonpath={.users[].user.client-key-data}' | xargs -0 printf "kubernetes_client_key=\"%s\"\n" >> terraform.tfvars
	@kubectl config view --raw --minify --flatten --output='jsonpath={.users[].user.client-certificate-data}' | xargs -0 printf "kubernetes_client_certificate=\"%s\"\n" >> terraform.tfvars
