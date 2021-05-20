# Backups

# Defining backups

Use the `enable_backups` and `schedules` to define k8s backups in a `*.auto.tfvars` file as follows:
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

