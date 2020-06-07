.PHONY: help

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

apply: ## Create or update the local manifests in the cluster
	source ../2-kops/cluster-config.sh && kubectl apply -f .

destroy: ## Destroy all resources defined by local manifests
	source ../2-kops/cluster-config.sh && kubectl delete -f .

get-prometheus-token: ## Get the token that will be used by Prometheus for scraping cluster metrics
	source ../2-kops/cluster-config.sh \
		&& kubectl get secret -n monitoring prometheus-service-account-token-692xw -o jsonpath={.data.token} | base64 -d
