# Kind

Layer used to create a local Kind cluster, exclusively for local testing/development

## Requirements

- Install Kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager
- Install kubectl (NOTE: kind does not require kubectl, but you will not be able to perform some of the examples in our docs without it.) https://kubernetes.io/docs/tasks/tools/#kubectl

## Instructions 

- Run make create-cluster to create the Kind cluster
- After this you can interact with it via kubectl

