# Backups

In order to have backups we have implemented [Velero](https://velero.io/), which provides tools to back up and restore Kubernetes cluster resources and persistent volumes.

This implementation uses the official [Velero Chart](https://artifacthub.io/packages/helm/vmware-tanzu/velero) according to the [official documentation](https://velero.io/docs/v1.6/) and the [AWS plugin](https://github.com/vmware-tanzu/velero-plugin-for-aws).



## Defining backups

Use the `enable_backups` and `schedules` to define Kubernetes backups in a `*.auto.tfvars` file as follows:
```
enable_backups = true
schedules = {
  cluster-backup = {
    target   = "all-cluster"
    schedule = "0 * * * *"
    ttl      = "24h"
  }
  argo-backup = {
    target             = "argcd"
    schedule           = "0 0/6 * * *"
    ttl                = "24h"
    includedNamespaces = ["argo-cd"]
  }
}
```

## Restore example

In order to restore resources, list the backups to identify the one you want to restore:

```
$ kubectl --kubeconfig ../cluster/kube_config get backups -A

NAMESAPECE    NAME                 AGE
velero        velero-argocd-20210519113027   1d2h
velero        velero-argocd-20210520124058   15m6s

```

Then use the `velero` command as follows to restore it:

```
$ velero --kubeconfig ../cluster/kube_config restore create --from-backup velero-argocd-20210520124058  --include-namespaces argo-cd

```

It will submit the restore task. To check its status use `describe`:

```
$  velero --kubeconfig ../cluster/kube_config restore describe velero-argocd-20210520124058-20210520104418
```

## TODOs

Things to evaluate:


* Update  **iam-assumable-role-with-oidc** module version to v.4.x. in the architecture to support a list of `provider_urls` in the roles to be assumed.
* Have a definition of clusters that allows to condense the oidc issuers in a tfstate to obtain a list of clusters and provide it to the **iam-assumable-role-with-oidc** module through the `provider_urls` parameter input.
