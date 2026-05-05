# EKS DemoApps Orchestration — Session Journal

Date: 2026-05-04
Branch: `feature/eks-demoapps-kgateway-private-gateway`
Cluster: `bb-apps-devstg-eks-demoapps` (v1.31, us-east-1)

## Outcome

Cluster orchestrated end-to-end (Steps 1-5 of `CLAUDE.md`), echo-server demo
app deployed and verified reachable over VPN. Step 6 (k8s-workloads full
sublayer) skipped per request.

## Step-by-step events

### Step 1 — network sublayer
- Flipped `vpc_enable_nat_gateway` from `false` to `true` in `network/terraform.tfvars`.
- Apply: 3 added (EIP, NAT Gateway `nat-0e2a5e8f4acfa8baf`, private route).

### Step 2 — cluster sublayer
- Apply: 50 added. EKS cluster + node groups (`standard_spot`, `tools_spot`)
  came up cleanly in ~22 min.

### Step 3 — identities sublayer
- Apply: 37 added (OIDC provider + IRSA roles for autoscaler, LB controller,
  cert-manager, external-dns private/public, external-secrets, fluent-bit,
  grafana, EBS/EFS CSI, VPC CNI, argocd image updater).

### Step 4 — addons sublayer
- Apply: 4 added.

### Step 5 — k8s-components sublayer (multiple iterations)

Local tfvars overrides kept per user instruction: `nginx_controller.enabled =
true`, `dns_sync.public.enabled = true`, `kgateway.enabled = false`.

Initial plan: 12 to add. Iterations:

1. **First apply** — 3 helm_release errors (`certmanager`,
   `clusterissuer_binbash`, `ingress_nginx_private`): all failed calling the
   `aws-load-balancer-webhook-service` mutating webhook. Root cause: the LB
   controller's webhook wasn't fully ready when downstream releases tried to
   create their Services. Order-of-operations / readiness race.

2. **Re-plan** — 9/12 succeeded. `certmanager` and `ingress_nginx_private`
   tainted; `clusterissuer_binbash` still pending. Retry-apply: certmanager +
   clusterissuer succeeded, `ingress_nginx_private` hit Terraform's helm 5m
   wait timeout (`context deadline exceeded`).

3. **Investigation** — Cluster-side, `ingress-nginx-private` controller pods +
   defaultbackend were Running. The release was healthy, only TF state was
   stuck. Used direct `tofu untaint helm_release.ingress_nginx_private[0]`
   (Leverage CLI doesn't proxy `untaint`) to clear the false taint.

4. **Re-plan** — 1 in-place change (status `failed → deployed`). Apply
   triggered a helm upgrade whose pre-upgrade hook (`ingress-nginx-private-
   admission-create` job) couldn't schedule:
   ```
   FailedScheduling: 0/2 nodes available — 1 Too many pods,
                     1 node(s) had untolerated taint {stack: tools}
   ```
   The standard_spot node had hit the kubelet `max-pods` limit; the
   tools_spot node was tainted. Cluster-autoscaler wasn't scaling up.

5. **Manual ASG scale-up** — Set `eks-standard_spot...` ASG `desired-capacity`
   from 1 to 2. New node `ip-10-1-48-244` joined the cluster.

6. **Re-apply** — Pre-upgrade hook ran. But helm upgrade still hit
   Terraform's 5m timeout (5m50s elapsed). Investigation showed the
   LoadBalancer Service `ingress-nginx-private-controller` was stuck with
   `<pending>` external IP. Root cause from Service events:
   ```
   FailedBuildModel: failed to parse bool annotation,
   service.beta.kubernetes.io/aws-load-balancer-internal: 0.0.0.0/0:
   strconv.ParseBool: parsing "0.0.0.0/0": invalid syntax
   ```
   Legacy CCM accepted the CIDR; AWS Load Balancer Controller requires a
   strict bool. The annotation source was
   `chart-values/ingress-nginx.yaml:16`. Sister file `traefik.yaml:9`
   already used the correct `"true"` value.

7. **Bug fix #1** — `chart-values/ingress-nginx.yaml:16`:
   `service.beta.kubernetes.io/aws-load-balancer-internal: 0.0.0.0/0` →
   `"true"`.

8. **Re-apply** — Apply complete: 0 added, 1 changed, 0 destroyed. NLB
   provisioned: `k8s-ingressn-ingressn-b7119792f0-9a62219d71cfeacb.elb.us-east-1.amazonaws.com`.

### Post-Step-5 fix — externaldns-private CrashLoop

`externaldns-private` pod was crashing with:
```
fatal: failed to sync *v1beta1.HTTPRoute: context deadline exceeded
```

Root cause: `networking-dns.tf:23` hardcoded `sources = ["ingress",
"gateway-httproute"]`, but with kgateway disabled the Gateway API CRDs aren't
installed. external-dns can't list HTTPRoutes → fatal.

**Bug fix #2** — `networking-dns.tf:23`:
```hcl
sources = var.kgateway.enabled ? ["ingress", "gateway-httproute"] : ["ingress"]
```
Apply: 0 added, 1 changed, 0 destroyed. Pod now Running.

### Echo-server demo app (k8s-workloads)

User asked for echo-server exposed VPN-only via nginx-ingress (no public).

- Rewrote `k8s-workloads/echo_server.tf` to drop the kgateway HTTPRoute
  resource and instead configure the helm chart's own `ingress` block:
    - Legacy class annotation `kubernetes.io/ingress.class: private-apps`
      (matches `--ingress-class=private-apps` flag the controller is launched
      with; same pattern used by argo-cd in this repo).
    - Hostname `echo-server.aws.binbash.com.ar`.
- First apply failed: chart expects `paths` as `["/"]` (list of strings), not
  list of maps with `path`/`pathType`. Fixed.
- Used `-target=helm_release.echo_server` because `emojivoto.tf` and
  `demo_google_microservices.tf` reference ArgoCD Application CRDs (ArgoCD is
  not enabled, so plan would fail otherwise).
- Apply complete. externaldns-private created the Route53 record.
- Verified end-to-end:
  ```
  $ dig +short echo-server.aws.binbash.com.ar
  10.1.64.42
  10.1.38.64
  $ curl http://echo-server.aws.binbash.com.ar/
  → HTTP 200, served by echo-server-6df5bc689f-r8dj5 via nginx
  ```

## Other notes

- **Stale kubeconfig gotcha**: `~/.kube/config` (default) had a previous
  cluster's endpoint cached, while `~/.kube/bb/apps-devstg` had the new one.
  When `KUBECONFIG` wasn't exported across Bash invocations, kubectl fell back
  to the default config and failed DNS lookup against the dead endpoint —
  initially mis-diagnosed as VPN being down. Always invoke kubectl with
  `KUBECONFIG=~/.kube/bb/apps-devstg`.

- **Leverage CLI scope**: The version installed (`/usr/local/bin/leverage`)
  exposes `apply / destroy / force-unlock / format / import / init / output /
  plan / refresh-credentials / validate / validate-layout / version`. No
  `untaint`, no `shell`. Used direct `tofu untaint` (with
  `AWS_CONFIG_FILE=~/.aws/bb/config AWS_PROFILE=bb-apps-devstg-devops`) when
  needed.

## kgateway phased rollout — Phase 0 (pre-flight verification)

Goal: bring kgateway up alongside nginx without breaking the existing setup.
Phase 0 was pure verification — no config changes.

- **cert-manager IRSA**: role `devstg-eks-demoapps-certmanager` in shared
  account already has `route53:ChangeResourceRecordSets` /
  `ListResourceRecordSets` scoped to the **public** zone (`aws_public_zone_id`)
  — exactly what `networking-kgateway.tf:259` pins the DNS01 solver to. The
  cert-manager SA carries the `eks.amazonaws.com/role-arn` annotation. The
  fall-through trick (`aws.binbash.com.ar` has no public NS delegation, so
  `_acme-challenge.aws.binbash.com.ar` queries climb to `binbash.com.ar`'s
  public NS where cert-manager can write) is intentional and works.
- **tools_spot capacity**: 1 node (t3.medium), 4/17 pods, 14% CPU / 6% mem.
  ASG `min=1, max=6`. Plenty of room for kgateway controller + Envoy.
- **Hostname inventory**: only `echo-server.aws.binbash.com.ar` was routed
  before Phase 1. No collision risk.
- **Gateway API CRDs URL**: HTTP 302 from
  `github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml`
  — reachable, redirects normal.

Outcome: nothing to change. Branch was pre-flight clean.

## kgateway phased rollout — Phase 1 (parallel deployment)

Single tfvars edit in `k8s-components/terraform.tfvars`:
`kgateway.enabled = false` → `true` (`private_gateway.enabled` was already
`true` locally).

### Two-stage apply (CRD plan-time validation issue)

`kubernetes_manifest.private_gateway` and `private_gateway_params` reference
CRDs (`gateway.networking.k8s.io`, `gateway.kgateway.dev`) that don't exist
in the cluster yet. Provider validates server-side at plan time → plan
errored with `API did not recognize GroupVersionKind from manifest (CRD may
not be installed)`.

Worked around with a two-stage apply within a single tfvar flip:

1. **Stage 1**: `tofu apply -target=kubernetes_manifest.gateway_api_crds
   -target=helm_release.kgateway_crds -target=helm_release.kgateway` —
   9 added (6 Gateway API CRDs + namespace + 2 helm releases for kgateway
   CRDs/controller). This makes the cluster aware of `Gateway`,
   `GatewayParameters`, etc.
2. **Stage 2**: full `tofu plan/apply` — 3 added
   (`private_gateway_params`, `private_gateway`, `private_gw_tls`) + 1
   in-place change (`externaldns_private` `sources` flipping from
   `["ingress"]` to `["ingress", "gateway-httproute"]` because of the
   `kgateway.enabled`-conditional we added in Step 5 cleanup).

Total Phase 1 footprint: 12 added, 1 changed.

### Validation after Phase 1

- 14 CRDs registered (6 Gateway API standard channel + 8 kgateway-specific).
- `kgateway` controller + `private-gw` Envoy data-plane pods Running on the
  tools node, both bound to the `stack: tools` taint via `GatewayParameters`.
- `GatewayClass kgateway` Accepted=True.
- `Gateway private-gw` Programmed=True. AWS LBC provisioned an internal NLB
  (target-type=ip) — `k8s-kgateway-privateg-83c4674872-cf58d1c83c50fd57.elb.us-east-1.amazonaws.com`
  — separate from the existing nginx-private NLB.
- HTTP listener Programmed=True immediately. HTTPS listener went from
  Programmed=False to True after ~3m30s when the LE wildcard cert (DNS01)
  was issued. Certificate `private-gw-wildcard` Ready=True with secret
  `private-gw-wildcard-tls`.
- `externaldns-private` pod restarted cleanly after the helm upgrade.
- Existing nginx Ingress for echo-server unchanged; `echo-server.aws.binbash.com.ar`
  still HTTP 200.

### Manual smoke test of the gateway data plane (no HTTPRoutes yet)

Before Phase 2, verified the kgateway listeners by curling the NLB hostname
directly. With no HTTPRoute attached, Envoy returns 404 — that's the proof
that the listeners are alive. HTTPS works with `--resolve` to pin a fake
host onto the NLB IP; the wildcard cert validates against any
`*.aws.binbash.com.ar` SNI.

## kgateway phased rollout — Phase 2 (echo-server smoke test, parallel)

Single resource added in `k8s-workloads/echo_server.tf`:
`kubernetes_manifest.echo_server_route` — an `HTTPRoute` attaching to
`kgateway-system/private-gw` via cross-namespace `parentRef`. Hostname
deliberately distinct (`echo-server-kg.aws.binbash.com.ar`) to avoid any
externaldns conflict with the existing nginx Ingress.

Targeted apply (same as before, because emojivoto / google-microservices
still reference ArgoCD CRDs that aren't installed):

```
tofu plan -target=kubernetes_manifest.echo_server_route -out=.tfplan
tofu apply .tfplan
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### End-to-end validation

- HTTPRoute `Accepted=True ResolvedRefs=True` against `private-gw`.
- `dig echo-server-kg.aws.binbash.com.ar` → `10.1.92.78` (kgateway NLB IP),
  distinct from the nginx NLB IPs (`10.1.38.64`, `10.1.64.42`).
- `curl http://echo-server-kg.aws.binbash.com.ar/` → HTTP 200.
- `curl https://echo-server-kg.aws.binbash.com.ar/` → HTTP 200, no `-k`
  needed (LE wildcard chain is publicly trusted).
- Cert presented: `CN=aws.binbash.com.ar`, issuer Let's Encrypt R12,
  SANs `*.aws.binbash.com.ar` + `aws.binbash.com.ar`.
- Both kgateway and nginx paths return responses from the same pod
  (`echo-server-6df5bc689f-r8dj5`), confirming both data planes share the
  echo-server backend Service.
- Existing nginx path unchanged — no regression.

Stable resting point: dual ingress data planes running in parallel, same
backend, no traffic shifted. Phase 3 (incremental migration) is opt-in
per-app whenever needed; nothing automatic.

## Day-2: midnight teardown lambda + recovery (2026-05-05)

Cluster has a scheduled lambda that nuke daytime resources every midnight
local time. By design — the cluster is intended to be ephemeral.

### Damage report (after the run)

| Component | State |
|---|---|
| EKS control plane | ✅ ACTIVE (etcd preserved: helm releases, HTTPRoutes, Ingresses, the LE wildcard cert Secret) |
| Managed node groups | ⚠ status=DEGRADED; `AutoScalingGroupNotFound` + `Ec2LaunchTemplateNotFound` |
| ASGs (both spot groups) | ❌ deleted |
| EC2 launch templates | ❌ deleted |
| EC2 instances | ❌ none |
| Internal NLBs (nginx + kgateway) | ❌ deleted |
| AWS LBC TargetGroupBindings (CRs in cluster) | ✅ persisted in etcd, but pointing at deleted TGs |
| NAT gateway | ✅ alive |
| IAM roles | ✅ alive |
| VPC, subnets | ✅ alive |
| EKS addons | ✅ alive (pods reschedule on new nodes) |

Key quirk: the EKS managed node group **objects** still existed in EKS even
though their backing ASG/LT were gone. So a plain `tofu plan` on the
`cluster` sublayer showed no drift. Forced replacement via `-replace=` was
required to make terraform actually rebuild them.

### Recovery sequence

1. **Force-replace the two node groups** (cluster sublayer):

   ```bash
   leverage tofu apply -auto-approve \
     -target='module.cluster.module.eks_managed_node_group["standard_spot"]' \
     -target='module.cluster.module.eks_managed_node_group["tools_spot"]' \
     -replace='module.cluster.module.eks_managed_node_group["standard_spot"].aws_eks_node_group.this[0]' \
     -replace='module.cluster.module.eks_managed_node_group["tools_spot"].aws_eks_node_group.this[0]'
   ```

   Scoping with `-target=` was necessary because the first attempt (without
   `-target`) errored on the `module.cluster-aws-auth` submodule — its
   kubernetes provider couldn't initialize during the refresh phase
   (`http://localhost/api/v1/.../aws-auth → connection refused`). Root cause:
   the data sources `aws_eks_cluster` / `aws_eks_cluster_auth` are declared
   with `depends_on = [module.cluster]`, so during a replace within
   `module.cluster` the provider config doesn't have its endpoint yet and
   defaults to localhost. Targeting the node-group submodules sidesteps the
   aws-auth code path entirely.

2. **Manually scaled `eks-standard_spot...` ASG `desired=2`** (same
   workaround as Day-1) to make room for the helm-hook + Pending pods.
   Tools_spot stays at 1.

3. **Stale TargetGroupBinding cleanup** — the most subtle issue. AWS LBC
   logs were full of:
   ```
   TargetGroupNotFound: Target groups 'arn:.../k8s-ingressn-ingressn-9860af82d3/...' not found
   ...
   creating targetGroupBinding ... resourceID":"ingress-nginx/.../80
   "targetgroupbindings.elbv2.k8s.aws "k8s-ingressn-ingressn-9860af82d3" already exists"
   ```

   AWS LBC builds TGB names deterministically from `(service, port)`. The
   pre-teardown TGBs persisted in etcd, still pointing at deleted target
   groups. New reconciliation tried to create TGBs with the same names →
   conflict. Result: the Service `.status.loadBalancer.ingress.hostname`
   stayed pinned to the dead NLB hostnames, externaldns happily said "all
   records up to date" against stale data, and DNS returned NXDOMAIN
   (because the dead hostnames have no A records anymore).

   Fix: delete all 4 stale TGBs (2 per Service: ports 80 + 443).
   ```bash
   kubectl delete targetgroupbinding -n ingress-nginx --all
   kubectl delete targetgroupbinding -n kgateway-system --all
   ```
   AWS LBC immediately recreated them against the live (post-teardown) NLBs
   and target groups; Service status flipped to the new hostnames.

4. **Restarted both `externaldns-private` and `externaldns-public`
   deployments** to skip the 3-min reconcile interval — instant Route53
   rewrite to the new NLB IPs.

### Validation after recovery

| Path | Result |
|---|---|
| `http://echo-server.aws.binbash.com.ar/` (nginx) | ✅ HTTP 200 |
| `http://echo-server-kg.aws.binbash.com.ar/` (kgateway HTTP) | ✅ HTTP 200 |
| `https://echo-server-kg.aws.binbash.com.ar/` (kgateway HTTPS, no `-k`) | ✅ HTTP 200 |

LE wildcard cert survived in etcd — no LE re-issuance needed. Both helm
releases and the kgateway Gateway/HTTPRoute are unchanged. From the user's
perspective the system is fully back to the post-Phase-2 state.

### Lessons for next morning's recovery

- Recovery does NOT require a terraform reapply of `k8s-components` or
  `k8s-workloads`. Only `cluster` sublayer needs the targeted node-group
  replace; everything else is k8s-side reconciliation + the manual
  TGB-cleanup nudge.
- Keep the `-target` scoped reapply pattern handy — without it,
  `cluster-aws-auth` will block recovery again.
- The TGB cleanup is the non-obvious step. If the cluster gets nuked
  again, look for `TargetGroupNotFound` + `already exists` pairs in the
  AWS LBC log and bulk-delete the conflicting TGBs.
- ASG bump to 2 on `standard_spot` is needed pre-helm-hook scheduling
  (same as Day-1).

## Day-2 follow-up: nginx echo-server TLS fix

After the recovery, a closer check showed the nginx HTTPS path was serving
its **default self-signed `Kubernetes Ingress Controller Fake Certificate`**
— the Ingress had `enabled = true` but no `tls` block / cert-manager
annotation, so port 443 fell back to the controller's built-in cert. Only
HTTP through nginx and HTTP/HTTPS through kgateway were properly working.

Fix in `k8s-workloads/echo_server.tf`: added cert-manager annotation +
TLS section to the helm-chart Ingress block, mirroring the argocd
convention that already exists in this repo:

```hcl
annotations = {
  "kubernetes.io/ingress.class"   = "private-apps"
  "cert-manager.io/cluster-issuer" = "clusterissuer-binbash-cert-manager-clusterissuer"
}
tls = [{
  hosts      = ["echo-server.aws.binbash.com.ar"]
  secretName = "echo-server-tls"
}]
```

cert-manager auto-created a `Certificate/echo-server-tls` from the
Ingress, drove it through DNS01 (public-zone fall-through, same trick the
kgateway wildcard uses), and populated the secret in ~94s. nginx-ingress
picked it up on next reconcile.

End-state: two parallel TLS strategies in play, both publicly trusted:

| Path | Cert |
|---|---|
| `https://echo-server.aws.binbash.com.ar/` (nginx) | LE per-host: `CN=echo-server.aws.binbash.com.ar` |
| `https://echo-server-kg.aws.binbash.com.ar/` (kgateway) | LE wildcard: `*.aws.binbash.com.ar` |

Per-host vs wildcard is intentionally different per data plane:
- **nginx**: cert-manager issues a fresh ACME order per Ingress (matches
  the argocd pattern). Scales linearly with apps.
- **kgateway**: single wildcard bound to the gateway listener at
  provision time; all apps behind the gateway share it.

## Outstanding (uncommitted) changes

- `network/terraform.tfvars` — flipped to `vpc_enable_nat_gateway = true`.
- `k8s-components/terraform.tfvars` — `kgateway.enabled = true` (Phase 1).
- `k8s-components/chart-values/ingress-nginx.yaml` — annotation fix (bug #1).
- `k8s-components/networking-dns.tf` — kgateway-conditional sources (bug #2).
- `k8s-workloads/echo_server.tf` — nginx-ingress Ingress (Phase 5 of
  orchestration) + parallel kgateway HTTPRoute (Phase 2 of kgateway
  rollout).
- `eks-standard_spot...` ASG — manually scaled to `desired=2` (cluster-
  autoscaler manages going forward; revert if you want fewer nodes).

Bugs #1 and #2 are real defects in the checked-in config; worth committing
independently of the kgateway / echo-server work.
