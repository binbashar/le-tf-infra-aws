# Kind

Layer used to create a local Kind cluster, exclusively for local testing/development

## Requirements

- Install [**Kind**](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager)
- Install [**kubectl**](https://kubernetes.io/docs/tasks/tools/#kubectl) (NOTE: kind does not require kubectl, but you will not be able to interact easily with the cluster without it.)

## Instructions

- Run `make create-cluster` to create the Kind cluster
- Run `make update-tfvars`
- After this you can interact with it via kubectl
- You can use `make help` to see the other availabe commands  

Kind will create a `config.yaml` file in `/kind` with a similar config as the one shown in the included `config.yaml.example` file.

After the cluster is created, you can use `leverage init/plan/apply` to start applying the terraform configs included in the layer.

For the Helm charts, you need to set the corresponding flags to true in `apps.auto.tfvars`. For example if you want to add fluentbit to the cluster, you need to set the following flags:


```
enable_logging = true
logging_forwarder = "fluentbit"
```




