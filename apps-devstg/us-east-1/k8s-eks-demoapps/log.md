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

All in-flight work from Day 1 is now committed:
- `f0bed101` — ingress-nginx config bug fixes + echo-server wired through both
  paths.
- `fb55c555` — nginx echo-server TLS (per-host LE cert).

---

# Day 2 — 2026-05-05

## Outcome

Full nightly teardown (orderly per-layer destroy) + morning re-orchestration.
Code-level fixes landed for the two recurring bootstrap speed bumps. End
state: same cluster footprint as Day 1 with sturdier node-group config.

## Nightly teardown (~01:15 local)

Reverse-order destroy of every layer (Option A from the proposed paths). The
goal was a clean slate for morning, not just a daytime resource sweep — so
state had to come down with the resources.

| Layer | Result |
|---|---|
| `k8s-workloads` | targeted destroy of `helm_release.echo_server` + `kubernetes_manifest.echo_server_route` (the two argoproj.io stub manifests in this layer fail plan-time validation since ArgoCD is not installed; they aren't in state, so targeted destroy sidesteps them) |
| `k8s-components` | **skipped** — `context deadline exceeded` on `helm_release.ingress_nginx_private` (5 min) and `kubernetes_namespace.kgateway` (4+ min). Underlying cause: the leftover `LoadBalancer` services and `TargetGroupBinding` CRs were waiting on AWS LBC, which had already been destroyed earlier in the same plan. Manual cleanup: deleted the two LB Services, patched the kgateway-system Service to drop the `service.k8s.aws/resources` finalizer, namespace finalized in seconds. NLBs were already gone in AWS (clean LBC uninstall removed them); two stale TGs in ELB v2 were deleted via CLI. |
| `addons` | 4 destroyed |
| `identities` | 37 destroyed |
| `cluster` | 50 destroyed |
| `network` | flipped `vpc_enable_nat_gateway = false` and applied — VPC kept, NAT down to stop the hourly bleed |

`k8s-components` state ended up with one stale entry: `kubernetes_namespace.ingress_nginx[0]`. Cheap to clean up next bootstrap.

## Morning re-orchestration

Same Steps 1–5 as Day 1, with the local tfvars overrides preserved (kgateway
on, nginx on, public dns_sync on). Step 6 skipped per request.

| Step | Layer | Notes |
|---|---|---|
| 1 | `network` | flipped NAT back on; 3 added |
| 2 | `cluster` | 50 added; ~17 min, no surprises |
| 3 | `identities` | 37 added |
| 4 | `addons` | 4 added |
| – | state cleanup | `tofu state rm 'kubernetes_namespace.ingress_nginx[0]'` (run via plain `tofu` — leverage CLI doesn't expose `state` subcommands) |
| 5 | `k8s-components` | two-stage targeted apply (same pattern as Day 1) |

### k8s-components quirks (re-encountered)

1. **kgateway CRD chicken-and-egg** — `kubernetes_manifest.private_gateway` and `private_gateway_params` validate at plan time against the live API, but the kgateway helm chart that installs `gateway.kgateway.dev` CRDs hadn't run yet. Resolved with the same two-stage flow:
   - Stage 1: `tofu apply -exclude='kubernetes_manifest.private_gateway' -exclude='kubernetes_manifest.private_gateway_params'` — installs everything else, including kgateway helm release (which lays down the CRDs).
   - Stage 2: `tofu apply` (no exclusions) — adds the 2 manifests against now-existing CRDs.
2. **AWS LBC webhook race** — same `failed calling webhook "mservice.elbv2.k8s.aws"` as Day 1 on first apply pass; cleared on retry.
3. **Spot capacity (us-east-1b, t3a.medium)** — `InsufficientInstanceCapacity` on the standard_spot ASG mid-Stage-1, all attempts failing. ASG eventually recovered across AZs after several minutes.
4. **cert-manager scheduling on a 1-node standard pool** — `FailedScheduling 0/2 nodes are available: 1 Too many pods, 1 node(s) had untolerated taint {stack: tools}`. Same as Day 1: t3.medium `max-pods=17` is exhausted by kube-system + a single deployment chain. Manually scaled the `eks-standard_spot...` ASG to `desired=2`. New node ready in ~90s, scheduling unblocked.

End state (verified): nodes Ready, no pending pods, both NLBs provisioned, `kgateway-system/private-gw` Gateway PROGRAMMED=True.

## Code-level fixes for the recurring speed bumps (commit `d8e9937e`)

`cluster/eks-workers-managed.tf`:

| | Before | After |
|---|---|---|
| `standard_spot` `min_size` / `desired_size` | 1 / 1 | 2 / 2 |
| Default + per-node-group `instance_types` | `[t3.medium, t3a.medium]` | `[t3.medium, t3a.medium, t2.medium, m5.large, m5a.large, m6a.large, m6i.large]` |

Why:
- **Floor of 2**: cert-manager's three deployments + AWS LBC + externaldns + autoscaler + nginx + kgateway exceed `t3.medium`'s pod limit. The cluster autoscaler can't help itself schedule (chicken-and-egg), so the *bootstrap* floor matters even with autoscaler running. Cost: roughly +$10/mo for one extra spot instance.
- **Broader pool**: shifts spot fulfillment from "one of 2 types in 3 AZs" (6 combos) to "one of 7 types in 3 AZs" (21 combos). `m*.large` is 4 GiB → 8 GiB and roughly 2× the price of t3.medium on spot, but the EKS module's `capacity_optimized` allocation strategy keeps cheap pools preferred — m-family is fallback, not default. Zero ongoing cost.

Apply was a node-group force-replace (instance_types is a replacement attribute). Used `-target='module.cluster.module.eks_managed_node_group["standard_spot"]'` and `tools_spot` to avoid the same `module.cluster-aws-auth` provider connection-refused chicken-and-egg from Day 1.

Final `tofu plan` clean, no drift.

## Day-2 follow-ups

### kgateway HTTP→HTTPS redirect (commit `d9db6a87`)

Spot check after re-orchestration revealed kgateway was serving the same
content on port 80 as port 443 — no redirect, unlike nginx. Root cause: the
`http` listener had `allowedRoutes.namespaces.from = "All"`, so app
HTTPRoutes (e.g. echo-server) auto-attached to *both* listeners. Combined
with Gateway API's "more specific hostname wins" routing, port 80 served
the app directly. Gateway API has no Gateway-level "redirect HTTP→HTTPS"
knob.

Fix: tightened the `http` listener to `from = "Same"` (only platform-
namespaced HTTPRoutes can attach), then added a single
`HTTPRoute/private-gw-https-redirect` in `kgateway-system` with
`sectionName: "http"` and a `RequestRedirect` filter (scheme=https,
statusCode=301). Apps don't need to opt in — the namespace policy on the
http listener silently rejects their attachment, so they're HTTPS-only by
construction.

Note: Gateway API restricts statusCode to 301/302 (rejects nginx's default
308). Used 301.

### Envoy Gateway as third data plane (commit `416a6f32`)

Added Envoy Gateway (CNCF, Envoy maintainers' official Gateway API
implementation) alongside nginx and kgateway. echo-server now reachable
via three parallel paths:

| Path | Endpoint | TLS |
|---|---|---|
| nginx | `https://echo-server.aws.binbash.com.ar/` | LE per-host |
| kgateway | `https://echo-server-kg.aws.binbash.com.ar/` | LE wildcard |
| Envoy Gateway | `https://echo-server-eg.aws.binbash.com.ar/` | LE wildcard |

Architecture mirrors kgateway: distinct GatewayClass (`envoy-gateway`),
namespace (`envoy-gateway-system`), and Gateway (`private-gw-eg`). Same
NLB pattern (AWS LBC, internal scheme, target-type=ip), same wildcard
cert pattern, same HTTP→HTTPS 301 redirect HTTPRoute. EG's `EnvoyProxy`
CR pins the data-plane Envoy pod to `stack=tools` and carries the three
NLB annotations on `envoyService.annotations`.

Notable structural difference: EG references `EnvoyProxy` at the
GatewayClass level (`spec.parametersRef`), unlike kgateway's
`GatewayParameters` which is referenced from each Gateway. All Gateways
using class `envoy-gateway` share the same EnvoyProxy params.

#### Refactor: shared ClusterIssuer

Extracted `clusterissuer-binbash-aws` from kgateway's TLS bundle into its
own `helm_release.cluster_issuer_binbash_aws` (in `certmanager`
namespace), gated on `var.certmanager.enabled && (var.kgateway.enabled ||
var.envoy_gateway.enabled)`. Each data plane now owns only its own
Certificate; neither is load-bearing for the other.

Transient pain during rollout: the new release adopted the existing
ClusterIssuer cleanly (after re-pointing its helm ownership annotations
via `kubectl annotate`), but the kgateway TLS upgrade ran *after* the
adoption and helm proceeded to delete the ClusterIssuer it tracked in
its v1 manifest. Recovered by `tofu apply -replace` on the new release.

Lesson: when refactoring resources between two helm releases under
terraform, stage the apply so the *donating* release upgrades before the
*adopting* release creates — otherwise helm's diff-against-v1-manifest
removes the resource right after adoption.

#### EG CRDs: bypass the helm subchart

`gateway-crds-helm` ships Gateway API standard + experimental + EG CRDs
in templates. Even with `crds.gatewayAPI.enabled=false`, the chart
*archive* exceeds etcd's 1 MB-per-Secret limit (the EnvoyProxy CRD alone
is 1.2 MB). Helm install fails with `Secret 'sh.helm.release.v1.envoy-
gateway-crds.v1' is invalid: data: Too long`.

Fix: pull the rendered EG CRDs YAML from the GitHub release page
(`https://github.com/envoyproxy/gateway/releases/download/v1.7.2/envoy-
gateway-crds.yaml`) and apply via `data.http` + `kubernetes_manifest`
for_each. Same pattern as the upstream Gateway API CRDs already in the
kgateway path.

The main `gateway-helm` chart needs `skip_crds = true` for the same
reason — its own bundled CRDs would clobber the ones we now manage
directly.

#### Misc

- external-dns sources gating is now `(kgateway || envoy_gateway) ?
  ["ingress", "gateway-httproute"] : ["ingress"]` — add new Gateway API
  consumers to the OR if/when needed.
- Clean `tofu plan`, no drift.
- All three Gateways carry distinct NLBs; total internal NLB count for
  this layer: 3 (nginx, kgateway, EG).

# Day 3 — 2026-08-03

## Outcome

Full stand-up from a cold start (cluster had been torn down and NAT disabled
by commit `5b0165ce`). Steps 1–5 applied; Step 6 (`k8s-workloads`) skipped
per request. Standard `terraform.tfvars` component set, no local overrides.

| Step | Layer | Result |
|---|---|---|
| 1 | `network` | 3 added (EIP + NAT GW + private route) — `nat-0deaf887913e16bfb` |
| 2 | `cluster` | 50 added, ~26 min. EKS 1.31, 3 nodes Ready first try |
| 3 | `identities` | 37 added |
| 4 | `addons` | 4 added (coredns, kube-proxy, vpc-cni, ebs-csi) |
| 5 | `k8s-components` | 3 passes, 34 resources; final `tofu plan` clean |

No spot-capacity or cert-manager scheduling issues this run — the node-group
hardening from `d8e9937e` appears to be holding.

## k8s-components: three passes

1. **Full apply (failed)** — aborted during its plan phase, nothing created.
   `kubernetes_manifest.private_gateway_params` (`GatewayParameters`) and
   `private_gw_eg_proxy` (`EnvoyProxy`) failed CRD validation. Note the
   *standalone* `tofu plan` beforehand reported a clean `34 to add` without
   these two — the plan under-reports what apply will validate, so a green
   plan is not proof the apply will get past its own plan phase.
2. **Stage 1, targeted** — 19 added:
   `-target=kubernetes_manifest.gateway_api_crds -target=helm_release.kgateway_crds
   -target=helm_release.kgateway -target=kubernetes_manifest.envoy_gateway_crds
   -target=helm_release.envoy_gateway`.
   Day-1/Day-2 used the kgateway targets only; **Envoy Gateway now needs the
   same treatment**, so both CRD sources belong in Stage 1.
3. **Stage 2, full apply (partial)** — 12 created, then the recurring AWS LBC
   webhook race killed `certmanager` and `ingress_nginx_private`
   (`no endpoints available for service "aws-load-balancer-webhook-service"`).
4. **Stage 3, re-apply** — 10 added, 2 destroyed (the two failed helm releases
   were recreated). Clean. Confirming plan: `No changes`.

## Gotcha: `leverage tofu` exit code is not trustworthy

`leverage tofu apply` returned **exit 0 on a failed apply** — twice, including
one where zero resources were created. Anything that gates on `$?` (background
job wrappers, CI, `&&` chains) will read a failure as success.

Always grep the captured output for `Apply complete!` / `^Error:` instead of
trusting the exit status. Also note `leverage` colorizes even when redirected,
so strip ANSI first:

```bash
leverage tofu apply -auto-approve 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' > apply.log
grep -E "^Apply complete|^Error:" apply.log
```

(A shell wrapper of the form `leverage tofu apply > log 2>&1; echo "EXIT=$?"`
compounds this — `$?` there is the redirect's status, not tofu's.)

## Validation

- 3 nodes Ready, zero pods outside `Running`.
- 22 gateway-related CRDs registered.
- `GatewayClass` `kgateway` and `envoy-gateway` both Accepted=True.
- Both Gateways PROGRAMMED=True with distinct internal NLBs:
  - `private-gw` (kgateway) → `k8s-kgateway-privateg-f5d44b7874-...`
  - `private-gw-eg` (Envoy Gateway) → `k8s-envoygat-envoyenv-7b8fa2cd58-...`
- LE wildcard certs (DNS01, `*.aws.binbash.com.ar`) Ready=True at 4m07s:
  `private-gw-wildcard` and `private-gw-eg-wildcard`.
- Both `http` and `https` listeners Programmed=True on both Gateways once the
  certs landed.

## kgateway removal — Envoy Gateway picked as the nginx-ingress replacement

Decision: EG is the Gateway API data plane going forward; kgateway removed
from the cluster and the code. nginx-ingress stays for now (it still serves
the `Ingress` path during the migration).

### The coupling that had to be broken first

`networking-kgateway.tf` owned the *shared* upstream Gateway API CRDs
(`data.http.gateway_api_crds` + `kubernetes_manifest.gateway_api_crds`),
gated on `var.kgateway.enabled`. EG consumes those same CRDs. Deleting the
file naively would have destroyed `Gateway`/`HTTPRoute`/`GatewayClass` CRDs
out from under EG and taken `private-gw-eg` with them. (`variables.tf` had
already flagged this: *"factor those CRDs out into a standalone resource
gated on any Gateway API consumer"*.)

Extracted them into **`networking-gateway-api.tf`**, keeping the resource
addresses identical so terraform sees no diff — only the `count` gate moved
from `var.kgateway.enabled` to `var.envoy_gateway.enabled`. The CRD version
pin moved from `var.kgateway.gateway_api_version` to a new
`var.envoy_gateway.gateway_api_version` (same `v1.4.0`, so no CRD churn).

Verified by the plan: **0 to add, 0 to change, 7 to destroy**, with
`kubernetes_manifest.gateway_api_crds`, `helm_release.cluster_issuer_binbash_aws`
and `helm_release.externaldns_private` all absent from the destroy/change
lists.

### What was destroyed

`helm_release.kgateway`, `helm_release.kgateway_crds`,
`helm_release.private_gw_tls`, `kubernetes_manifest.private_gateway`,
`kubernetes_manifest.private_gateway_params`,
`kubernetes_manifest.private_gateway_https_redirect`,
`kubernetes_namespace.kgateway`. Namespace terminated cleanly in 15s — no
TargetGroupBinding finalizer hang this time (the Gateway is deleted before
the namespace, so LBC tears the NLB down in order).

### Orphan: the `kgateway` GatewayClass

`helm uninstall` left the cluster-scoped `GatewayClass/kgateway` behind. It
carries **no helm labels/annotations** — the kgateway *controller* creates it
at runtime (`gatewayClass.enabled` in the chart values), so helm never owned
it, and it lives on a CRD (`gatewayclasses.gateway.networking.k8s.io`) that
deliberately survives. Removed manually:

```bash
kubectl delete gatewayclass kgateway
```

Worth remembering for any future data-plane removal: controller-created,
cluster-scoped objects on shared CRDs won't come out with terraform or helm.
A sweep of deployments/services/configmaps/secrets/serviceaccounts/
clusterroles/clusterrolebindings/webhookconfigurations found nothing else.

### Code touched

| File | Change |
|---|---|
| `k8s-components/networking-gateway-api.tf` | **new** — shared Gateway API CRDs, gated on EG |
| `k8s-components/networking-kgateway.tf` | deleted |
| `k8s-components/chart-values/kgateway.yaml` | deleted |
| `k8s-components/variables.tf` | `kgateway` variable removed; `gateway_api_version` added to `envoy_gateway` |
| `k8s-components/terraform.tfvars` | `kgateway` block removed |
| `k8s-components/locals.tf` | kgateway tags removed; CRD URL re-pointed |
| `k8s-components/namespaces.tf` | `kgateway-system` namespace removed |
| `k8s-components/networking-dns.tf` | external-dns `sources` gate → EG only |
| `k8s-components/networking-cluster-issuer.tf` | kgateway clause dropped from `count` |
| `k8s-workloads/echo_server.tf` | kgateway HTTPRoute + `echo-server-kg` host removed |
| `loadtest/echo-server-k6.js`, `README.md`, `k6-job.yaml` | kgateway host dropped from the scenarios |

`loadtest/test-results.md` left untouched — it's the record of the three-way
benchmark that motivated the decision, so it still reports kgateway numbers.

### Validation

- `k8s-components`: `tofu plan` → `No changes`.
- `k8s-workloads`: `tofu plan` → 4 to add, only `echo_server_route_eg`
  (layer not applied; run as a code/CRD sanity check).
- `GatewayClass` list: `envoy-gateway` only.
- `private-gw-eg` still PROGRAMMED=True, `private-gw-eg-wildcard` Ready=True,
  6 standard-channel Gateway API CRDs still registered, 0 `kgateway.dev` CRDs.

## echo-server deployed on both data planes — and the client-IP gotcha

Deployed `k8s-workloads` with `echo_server.enabled = true` to validate nginx
and Envoy Gateway side by side. 5 added (the namespace is new, see below).

| Host | Data plane | HTTPS | TLS | HTTP |
|---|---|---|---|---|
| `echo-server.aws.binbash.com.ar` | nginx-ingress | 200 | LE cert, verified | 308 → https |
| `echo-server-eg.aws.binbash.com.ar` | Envoy Gateway | 200 | LE wildcard, verified | 301 → https |

Both served by the same pod. The 308/301 split is expected, not a defect:
Gateway API only permits 301/302, so the EG redirect HTTPRoute uses 301 while
nginx keeps its default 308.

### Namespace had to be brought under terraform

`echo_server.tf` referenced the `echo-server` namespace by string and left it
unmanaged, on the theory that it survived from the old Ealenn helm release
(helm doesn't delete namespaces on uninstall). That holds only until the
cluster is rebuilt — which this layer does routinely. On the fresh cluster
the namespace didn't exist and all four resources would have failed to apply.
Added `kubernetes_namespace.echo_server` and switched every resource to
reference it by attribute so terraform infers the ordering (commit
`fea11b3b`).

### The client IP does not survive the Envoy Gateway path

echo-server echoes the request verbatim, which makes the two paths trivially
diffable. Two levels of difference showed up.

**Cosmetic — injected header sets:**

| | nginx | Envoy Gateway |
|---|---|---|
| headers | `X-Forwarded-For`, `X-Forwarded-Host`, `X-Forwarded-Port`, `X-Forwarded-Proto`, `X-Forwarded-Scheme`, `X-Real-Ip`, `X-Request-Id`, `X-Scheme` | `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Request-Id`, `X-Envoy-External-Address` |
| `X-Request-Id` format | 32-char hex | UUID |

Migration note: any app reading `X-Real-Ip` or `X-Forwarded-Host` breaks on
EG — nginx synthesises those, EG does not.

**Functional — `X-Forwarded-For` is wrong on the EG path:**

- nginx → `10.1.49.167`, the actual client pod IP
- EG → `10.1.56.214`, which is the EG NLB's own IP

Root cause confirmed against the AWS API (not inferred from the header
alone):

| | nginx NLB | EG NLB |
|---|---|---|
| target-type | `instance` | `ip` |
| `preserve_client_ip.enabled` | **true** | **false** |
| `proxy_protocol_v2.enabled` | false | false |

nginx-private's target groups are `instance` type (NLB → worker NodePort,
`externalTrafficPolicy: Local`), where AWS preserves the source IP and it
can't be turned off. EG's are `ip` type (NLB → Envoy pod ENI directly), and
for `ip` target groups on TCP, AWS defaults `preserve_client_ip` to **false**.
Envoy therefore sees the connection as originating from the NLB and puts that
in `X-Forwarded-For`.

Impact: behind EG as configured today, anything keying on client IP — rate
limiting, allow-lists, audit logging, geo — is blind.

The tension: `ip` target-type is precisely what makes EG faster (no NodePort
hop) and what keeps it clear of the client-side timeout tail the benchmark
found on nginx's `instance` path. So flipping EG to `instance` targets trades
away the reason it was chosen. Two better options, neither tried yet:

1. `preserve_client_ip.enabled=true` on the target group, via
   `service.beta.kubernetes.io/aws-load-balancer-target-group-attributes` in
   the `EnvoyProxy` `envoyService.annotations`. One-line change, but client-IP
   preservation on `ip` targets can break traffic that leaves and re-enters
   the same node (hairpinning).
2. Proxy protocol v2 on the NLB plus EG `clientIPDetection` configured to
   parse it. More moving parts, but it's the AWS-recommended route for `ip`
   targets.

This needs resolving before nginx-ingress is actually retired, not after.
