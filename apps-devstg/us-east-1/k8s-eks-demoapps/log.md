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

## Public Envoy Gateway with an IP allowlist (commit `82089bbe`)

Added an internet-facing counterpart to `private-gw-eg`, so the layer now has
both a VPN-only and a public HTTPS entry point. `echo-server` gained a third
hostname, `echo-server.binbash.com.ar`, alongside its two private ones.

EG resolves `EnvoyProxy` through `GatewayClass.parametersRef`, not per Gateway,
so the public data plane needed its own GatewayClass (`envoy-gateway-public`)
rather than reusing `envoy-gateway`. Naming is asymmetric as a result — the
private class kept its original name because `gatewayClassName` is immutable
and renaming would recreate the Gateway and its NLB.

Three decisions worth remembering:

1. **The allowlist is enforced at the NLB security group, not in Envoy.** The
   NLB uses `target-type: ip` and does not preserve the client address, so a
   `SecurityPolicy` with `principal.clientCIDRs` would match against the load
   balancer's own IP. Confirmed empirically: requests arrive at Envoy with
   `X-Forwarded-For: 10.1.132.115` (the NLB ENI). Same root cause as the
   client-IP gotcha logged above — worth solving once, for both.
2. **The CIDR list is a standalone variable** read from
   `allowlist.local.auto.tfvars`, which `.gitignore` excludes
   (`*.local.auto.tfvars` — deliberately narrower than `*.auto.tfvars`, which
   is a versioned convention elsewhere in this repo). It is top-level rather
   than a field of `envoy_gateway` because tfvars files cannot merge into an
   object variable. A `precondition` on the `EnvoyProxy` fails the plan when
   the list is empty, since the LBC would otherwise default the SG to
   `0.0.0.0/0`.
3. **The public HTTPS listener uses an `allowedRoutes` label Selector**, not
   `from: All`. A namespace must carry
   `gateway.binbash.com.ar/public-exposure=allowed` before anything in it can
   attach, so writing an HTTPRoute is not by itself enough to reach the
   internet.

Supporting changes: a second DNS01 solver on the shared ClusterIssuer for the
public zone (backing a `*.binbash.com.ar` wildcard, apex deliberately excluded);
`externaldns-public` now watches `gateway-httproute` and drops its
`annotationFilter` (annotation filters apply across *all* sources, so keeping it
would have silently excluded every HTTPRoute), with a new
`excludeDomains: [aws.binbash.com.ar]` to stop the public release's
`binbash.com.ar` filter from publishing private hostnames into the public zone.

### Gotcha: how *not* to verify an IP allowlist

The first negative test was a false pass, for two compounding reasons:

- **`WebFetch` egresses from the operator's own machine**, not from remote
  infrastructure — verified against `api.ipify.org`, which returned the same
  IPv4 as a local `curl -4 https://ifconfig.me`. It cannot serve as an
  "external" vantage point.
- **Security groups are stateful.** After tightening the rules, an established
  keep-alive connection kept working. Visible in the backend logs as two
  requests five minutes apart from the *same* source port
  (`10.1.3.159:46936`).

What actually proves it: an A/B on the allowlist itself — real CIDR → `HTTP
200`; `192.0.2.0/24` (TEST-NET) → timeout from the same client; restore →
`200` again. Force fresh connections with `curl --no-keepalive`.

## Teardown (Day 3 → Day 4, ~23:30 local)

Destroyed in reverse order, keeping the VPC per the `5b0165ce` pattern.

| Layer | Result |
|---|---|
| `k8s-workloads` | 6 destroyed |
| `k8s-components` | 4 passes — see below |
| `addons` | 4 destroyed |
| `identities` | 37 destroyed |
| `cluster` | 50 destroyed, clean |
| `network` | 3 destroyed — NAT GW, EIP, private route. VPC kept |

The `network` step ran after an interruption: the per-profile credentials for
the *network* account had gone stale mid-teardown. The SSO token itself was
still valid for hours, so `leverage tofu refresh-credentials` was enough — no
interactive `leverage aws sso login` was needed. Worth checking the token
expiry before assuming a re-login is required.

Final state verified: no EKS clusters, load balancers, EC2 instances, NAT
gateways, EIPs, or `k8s-*` security groups. VPC `vpc-0c2dd28735d0250c3` remains
with a clean `No changes` plan, ready for a fast re-spin — flip
`vpc_enable_nat_gateway` back to `true` before re-running the `cluster` layer.

Waited a full `external-dns` sync cycle (~100 s) between `k8s-workloads` and
`k8s-components` so the Route53 records were removed while the controller was
still alive. Both zones verified empty before continuing.

### The finalizer deadlock — this will recur

Terraform deleted the helm releases for the Envoy Gateway controller **and the
AWS Load Balancer Controller before the `Service`s of type LoadBalancer that
they manage**. All three Services were left holding the
`service.k8s.aws/resources` finalizer, which only the LBC can remove — with no
LBC left, `envoy-gateway-system` sat in `Terminating` indefinitely and the
destroy timed out (`context deadline exceeded`).

The LBC did manage to delete the three NLBs in AWS before it went away, so
nothing was left billing. That was luck, not design: had it died a moment
earlier, three orphaned NLBs would have survived every subsequent destroy.

Recovery: strip the finalizers by hand
(`kubectl patch svc <name> -n <ns> -p '{"metadata":{"finalizers":null}}'
--type=merge`), after confirming the AWS resources were already gone. The
namespace then terminated on its own.

**Fix to make:** `depends_on` tying the controller helm releases
(`alb_ingress`, `envoy_gateway`) to the Gateways/Ingress objects they manage,
so Terraform tears them down last.

> **Correction (Day 4).** The diagnosis above is wrong, and acting on it would
> have been a no-op: those `depends_on` were *already in place* during this
> teardown. The ordering was never the problem — the cleanup is asynchronous.
> See "The finalizer deadlock, re-diagnosed" under Day 4 for what actually
> fixes it.

### Second blocker: `kubernetes_manifest` validates at plan time

Once the CRDs were gone, `tofu destroy` failed on
`kubernetes_manifest.{private,public}_gw_eg_proxy` with
`no matches for kind "EnvoyProxy"` — the provider validates the manifest
against the live API during *plan*, even for resources no longer in state.
Worked around with `-target` on the three remaining resources, which prunes the
rest of the graph. Setting the layer's `enabled` toggles to `false` before
destroying would also work, at the cost of touching versioned code.

## Outstanding (uncommitted) changes

- `network/terraform.tfvars` — `vpc_enable_nat_gateway = false`, applied to AWS
  but not committed.
- `shared/us-east-1/tools-atlantis-ecs/main.tf` — removed a hardcoded personal
  IP from an ALB security-group rule. That layer is not deployed, so no plan or
  apply was run. The same IP remains in published history (commit `e7f6bfb8`,
  PR #880).
- `k8s-components/allowlist.local.auto.tfvars` — gitignored by design, but
  **required**: without it the public gateway fails its precondition. Recreate
  from `allowlist.local.auto.tfvars.example` if the working tree is cleaned.

The branch is 6 commits ahead of origin and nothing has been pushed.

# Day 4 — 2026-08-04

## Outcome

Full re-spin of the stack that was torn down ~10 hours earlier, plus the
destroy-ordering fix from backlog item 1. About an hour of wall clock, most of
it the EKS control plane.

| Layer | Result |
|---|---|
| `network` | 3 added — NAT GW, EIP, private route. Mirror of the teardown |
| `cluster` | 50 added — EKS 1.34.9 / AL2023, 3 spot nodes |
| `identities` | 37 added |
| `addons` | 4 added — vpc-cni, coredns, kube-proxy, ebs-csi |
| `k8s-components` | 14 CRDs + controller (stage 1), then 24 resources (stage 2) |
| `k8s-workloads` | 6 added |

Re-enabling the NAT gateway was just `git checkout` on
`network/terraform.tfvars` — the only uncommitted delta in that file was the
`vpc_enable_nat_gateway` flip, so restoring the committed state is the whole
"cost-up" step.

Stale per-profile credentials for the *network* account showed up again at the
start, with the SSO token still valid — `leverage tofu refresh-credentials`,
same as during the teardown. Worth trying before an interactive re-login.

## The finalizer deadlock, re-diagnosed

Backlog item 1 asked for `depends_on` tying the controllers to the objects they
manage. **That was already there**, and predates the teardown that deadlocked:

- `networking-envoygateway.tf` private gateway → `alb_ingress`, commit
  `416a6f32a` (2026-05-05)
- ditto for the public gateway, commit `82089bbe` (2026-08-03 22:43) — roughly
  45 minutes *before* the 23:30 teardown

So Terraform did delete the Gateways before the controllers, and the Services
still hung. The ordering was never the issue.

The real mechanism is **asynchronous garbage collection**. Deleting a `Gateway`
returns as soon as the CR is gone from etcd, but the derived `Service` of type
LoadBalancer is collected by the Envoy Gateway controller some seconds later,
and only then does the LBC delete the NLB and strip its
`service.k8s.aws/resources` finalizer. Terraform waits for none of that — it
moves straight on to destroying both controllers, killing them mid-cleanup.
No `depends_on` can express "wait for a controller to finish reconciling".

The fix is a drain gate — `time_sleep.controller_drain` in
`networking-ingress.tf`, `destroy_duration = "180s"`. The dependency direction
is inverted from what reads naturally: the sleep depends on the *controllers*,
and the managed objects depend on the *sleep*, so the reverse-order destroy
produces

```
Gateways / ingress controllers  ->  [ wait 180s ]  ->  LBC + Envoy Gateway
```

Attached to: both Envoy Gateways, `nginx_apps`, `traefik_apps`,
`ingress_nginx_private` and `traefik`. That last pair is a separate, genuine
gap found along the way — both own a `Service` of type LoadBalancer and had **no
ordering declared at all** against `alb_ingress`, so nothing stopped Terraform
from killing the LBC first. Requires the `time` provider, added to `config.tf`.

Cost: 180s added to every destroy. **Not yet exercised against a real destroy** —
it only gets validated at the next teardown.

## k8s-components: the two-stage apply, again

Same plan-time CRD validation problem as Day 2, now with Envoy Gateway instead
of kgateway. A fresh cluster has no `gateway.envoyproxy.io` CRDs, so the
`EnvoyProxy` manifests fail the plan with `no matches for kind "EnvoyProxy"`.

```
leverage tofu apply -target=kubernetes_manifest.gateway_api_crds \
                    -target=kubernetes_manifest.envoy_gateway_crds \
                    -target=helm_release.envoy_gateway
```

After that the full plan is clean (24 to add). Worth folding into the layer's
own docs eventually — this is the third time it has bitten.

## Gotcha: the CRD downloads are flaky over the VPN

Both `data "http"` blocks (Gateway API CRDs, EG CRDs) failed with
`net/http: TLS handshake timeout` on two of four attempts, and the http
provider gives up after **1** attempt. The same file from the host took 12s,
so the VPN is the likely culprit. Plain retries got through.

Two traps this creates:

- The failure is silent-ish in its consequences: `try(..., "")` on the response
  body turns a failed fetch into an *empty* `for_each` map, so a targeted apply
  reports `0 added` / `No changes` rather than an error.
- Because of that, one of the intermediate retries succeeded without being
  noticed, and a later attempt reported "no changes" that looked like a
  failure. Confirming against the cluster (`kubectl get crd`, pod age) settled
  it — the state, not the apply output, is the source of truth here.

A `retry` block on both `data "http"` blocks would remove this entirely. Not
done yet.

## Red herring: NLB health-check convergence

Shortly after the apply, both target groups of the **public** gateway read
`unhealthy` (`Target.FailedHealthChecks` on port 10080) while the private
gateway and nginx were healthy. The asymmetry pointed straight at the IP
allowlist, and a fair amount of digging went into security groups before the
obvious check: the node SG already allowed the shared `k8s-traffic-*` SG on
10080-32113, and the health-check config was byte-identical between the two.

Re-polling a few minutes later: both healthy. It was simply convergence — an
internet-facing NLB takes longer to register targets than an internal one.
**Re-check before investigating asymmetric health between two NLBs.**

## Validation

All pods `Running`, both Gateways `PROGRAMMED=True`, both GatewayClasses
`ACCEPTED=True`, both wildcard certs issued (the private one via DNS01 took
~4 min — the HTTPS listener and its `443` target group only appear once the
cert lands), all six target groups healthy, no orphaned TargetGroupBindings.

| Endpoint | Path | Result |
|---|---|---|
| `echo-server.aws.binbash.com.ar` | nginx private ingress | `200` |
| `echo-server-eg.aws.binbash.com.ar` | private Envoy Gateway | `200` |
| `echo-server.binbash.com.ar` | public Envoy Gateway (allowlist) | `200` |

The allowlist still held yesterday's `/32` and the egress IP had not changed,
so no edit was needed. The negative case was **not** re-tested — that needs the
A/B on the allowlist itself described under Day 3.

One wrinkle: with the VPN up, the local resolver returns nothing for
`echo-server.binbash.com.ar`, even though the record is live and correct.
Confirmed via `dig @8.8.8.8` and curled with `--resolve`. A VPN DNS artifact,
not an infrastructure fault — but it makes the public endpoint look broken from
the operator's machine.

Also worth noting: `external-dns` syncs every **3 minutes** (`Interval:3m0s`),
not the ~100s assumed during the teardown. Records for a freshly applied
workload can take that long to appear.

## nginx → Envoy migration: planned, and the client-IP blocker cleared

Backlog item 2 started here. The inventory it asked for came back smaller than
expected: **echo-server is the only live nginx consumer.** `kubectl get
ingress -A` returns exactly one object; argocd, gatus, goldilocks and
`apps_ingress` all sit at `enabled = false`. The migration surface is one
Ingress, not a set.

### The constraint that shapes the cutover

`externaldns-private` watches `sources = ["ingress", "gateway-httproute"]`
under a single `txtOwnerId` with policy `sync`. One instance, both worlds, same
zone. If the nginx Ingress and an Envoy HTTPRoute claim
`echo-server.aws.binbash.com.ar` simultaneously, external-dns holds two
different targets for one record and the winner depends on its internal dedup
order. So the hostname can only be claimed by one object at a time — unless the
other is hidden from external-dns.

Also worth knowing, because it is a lever people reach for and it does not
exist here: the records are ALIAS to an NLB, and Route53 imposes the target's
TTL (60 s) on ALIAS. You cannot pre-lower it to speed up a flip.

**Chosen approach — dark launch.** A HTTPRoute carrying the new hostname with
`external-dns.alpha.kubernetes.io/controller` set to a value external-dns
ignores, validated with `curl --resolve` straight at the Envoy NLB, then one
apply that removes the host from the Ingress and drops the annotation. It is
the only option that exercises the real hostname, real cert and real path
before DNS moves. The final state should fold the hostname into the existing
`echo-server-eg` HTTPRoute as a second entry, so the `-eg` name stays live as
an instant rollback and its later removal is a one-line delete.

### Client IP: fixed, and the received wisdom was wrong

Retiring nginx was blocked on the Day-3 finding that `X-Forwarded-For` carries
the NLB's own address on the Envoy path. Fixed by moving `private-gw-eg`'s NLB
to `nlb-target-type: instance` — one annotation. Verified end to end:

| | before | after |
|---|---|---|
| envoy `X-Forwarded-For` | `10.1.34.126` (the NLB) | `172.18.7.44` (real client) |

Two details worth keeping. `preserve_client_ip` is **not** a companion setting:
on `instance` target groups AWS preserves the source IP and it cannot be
disabled, so the target-type alone is the whole fix. And it needs
`externalTrafficPolicy: Local`, which Envoy Gateway already defaults to — so
nothing had to be set, but do not assume that across EG upgrades.

The change was adopted expecting to pay for it with nginx's timeout tail, which
five scenarios had pinned on `instance` mode. **That turned out to be false.**
S6 in `loadtest/test-results.md` is the controlled test that was never run:
with both data planes on identical `instance`-target plumbing, envoy logged
**zero** failures over 450 k requests and nginx logged 425 (0.09%) in the same
window. The tail is nginx's, not the target-type's — and the long-standing
"nginx → envoy → kgateway" latency ordering was partly an artifact of the
target-type difference, since the two are indistinguishable on equal footing.

The first attempt at that run was voided by spot interruptions that reclaimed
both the k6 node and the Envoy `tools` node, and `ttlSecondsAfterFinished: 600`
then garbage-collected the failed Job before its logs could be read. The TTL
has been removed from `k6-job.yaml`; the comment defending it was wrong on the
facts (it claimed the surviving Namespace kept logs browsable — logs live in
the pod, which the Job deletes with itself).

### Decisions taken

- **The `tools` node group stays at desired = 1.** When it was reclaimed
  mid-run the private gateway had zero healthy targets until Envoy
  rescheduled — with `instance` + `Local`, only nodes running an Envoy pod pass
  the health check, and an ALIAS record with `EvaluateTargetHealth: true`
  returns NODATA rather than merely failing. Accepted deliberately: this is a
  disposable test cluster, not a permanent one. Revisit (desired = 2 plus a
  `topologySpreadConstraint`) only if that ever changes.
- **The public gateway stays on `ip` targets.** Its NLB carries the allowlist
  in its security group, and preserving client IP changes which source address
  the node's SG rules are evaluated against. Deliberately not bundled with the
  private-gateway change.
- **The inverse benchmark (nginx on `ip` targets) is declined** — nginx is
  being replaced, so the answer changes nothing actionable.

## Executing the migration — nginx-ingress retired

Ran the four steps the same day the plan was written. `echo-server` was the
only consumer, so this was one hostname moving between data planes.

**(a) Dark launch.** A transient HTTPRoute carrying
`echo-server.aws.binbash.com.ar` with
`external-dns.alpha.kubernetes.io/controller: none-cutover-dark-launch`, so
Envoy would route the name while external-dns kept publishing nginx's record.
Separate route rather than a second hostname on `echo-server-eg`, because that
annotation is per-resource and would have un-published the `-eg` record too.

Validated with `curl --resolve` straight at the Envoy NLB: HTTP 200 on the real
hostname, valid TLS off the wildcard with no `-k`, and `X-Forwarded-For`
carrying the real client IP. Confirmed it stayed dark across two full 3-minute
sync cycles — external-dns logged `All records are already up to date` every
cycle and the ALIAS still pointed at `k8s-ingressn-…`. So the `controller`
annotation is honoured on the `gateway-httproute` source in v0.14.0, which had
been an assumption up to that point.

**(b) The cutover.** One apply: hostname added to `echo-server-eg`, transient
route destroyed, nginx Ingress destroyed. The Ingress was deleted outright
rather than emptied — that host was its only rule. The ALIAS flipped to the
Envoy NLB **160 s** later, inside the expected window.

This opened a real gap: DNS still pointed at nginx while nginx no longer had a
route for the name, so the hostname 404s for up to one sync cycle plus the 60 s
ALIAS TTL. The `-eg` name covered it.

> **This was avoidable, and calling it inherent to DNS-based cutovers (as this
> entry first did) was wrong.** The mistake was bundling "stop serving the old
> path" into the same apply that moved DNS. DNS is eventually consistent; the
> Ingress deletion is not.
>
> The fix is to invert *which* object is hidden from external-dns. Annotate the
> **nginx Ingress** with
> `external-dns.alpha.kubernetes.io/controller: none` and leave it in place:
> nginx-ingress does not read that annotation, so it keeps serving, while
> external-dns stops seeing it and the HTTPRoute becomes the only source for
> the name. The ALIAS repoints while *both* data planes still answer — clients
> on the new record go through Envoy, clients on a cached record still get 200
> from nginx. Only once DNS has fully propagated is the Ingress deleted.
>
> Correct order, four applies instead of three:
> 1. Dark launch on a transient hidden route; validate with `curl --resolve`.
> 2. Hostname onto the main HTTPRoute **plus** the ignore annotation on the
>    Ingress — do not delete it.
> 3. Wait one sync + TTL, verify over real DNS.
> 4. Delete the Ingress, then disable nginx.
>
> The repoint itself contributes nothing: external-dns issues an UPSERT and the
> Route53 change is atomic, so a resolver sees the old target or the new one,
> never NXDOMAIN — the observed 160 s flip was a clean repoint, not a
> delete-then-create. If a future migration needs a *percentage* canary rather
> than merely a gapless flip, that is a different mechanism: Route53 weighted
> records via external-dns `set-identifier`.
>
> Use this ordering for the next data-plane migration. It was not re-tested
> here because nginx is already gone.

**(c) Retiring `-eg`.** Dropped from `hostnames`; policy `sync` deleted the
Route53 record within 20 s.

**(d) nginx off.** `nginx_controller.enabled = false` → 2 destroyed (helm
release + namespace) in 1m45s. **No finalizer deadlock** — the namespace
terminated on its own, no orphaned TargetGroupBindings, and the nginx NLB was
removed in AWS. That is the expected outcome when the LBC outlives what it
manages, which is exactly what the Day-4 drain gate is meant to guarantee at
teardown; this run only exercised the easy half of it (the controllers were
never in scope), so the gate itself is still unverified.

`local.private_ingress_class` was kept, not deleted, with a note explaining it
is now a dead class: argocd, kube-prometheus-stack, uptime-kuma, gatus and
goldilocks still reference it, all disabled. Re-enabling any of them produces
an Ingress no controller will serve; they need HTTPRoutes against
`private-gw-eg` instead. Keeping the local means those references still resolve
and the warning stays attached to them.

Final state: two hostnames, both on Envoy Gateway, both 200, client IP
preserved, and only two NLBs left in the account.

### AWS WAF is not deployed at all

Backlog item 4 reads as though WAF has to be preserved across the migration.
It does not: nothing in this stack has a WebACL attached. The only traces are
IAM permissions on the LB controller role (so it *could* associate one) and
`apps-devstg/us-east-1/security-firewall --`, whose trailing ` --` marks it
excluded from deployment. `apps_ingress`, the ALB→nginx path it would have
attached to, is also disabled. So item 4 is "decide whether to build this",
not "avoid breaking it" — and it does **not** block the echo-server cutover.

## Outstanding (uncommitted) changes — updated

- `network/terraform.tfvars` — **restored** to `vpc_enable_nat_gateway = true`
  and applied. No longer a pending delta.
- `k8s-components/{config.tf,networking-ingress.tf,networking-envoygateway.tf}`
  — the drain-gate fix described above. Applied, not committed.
- `shared/us-east-1/tools-atlantis-ecs/main.tf` — unchanged from Day 3; still
  the hardcoded-IP removal on an undeployed layer.
- `k8s-components/allowlist.local.auto.tfvars` — still gitignored and still
  required.

# Day 5 — 2026-08-04

## Both gateways on `instance` targets — backlog item 7 closed

Item 7 asked how client-IP preservation would interact with the allowlist
living in the NLB security group, on the assumption that preserving the client
IP changes which source address the node's SG rules are evaluated against. The
assumption was wrong, in two independent ways, and neither needed a test to
settle — the answer was already in the account.

**The allowlist is not a node-side rule.** It sits on the NLB's own frontend
security group, `k8s-envoygat-envoyenv-e0db197f0c` ("[k8s] Managed
SecurityGroup for LoadBalancer"), which the LBC creates from
`load-balancer-source-ranges` and attaches to the load balancer. Inbound client
traffic is evaluated there, before the NLB forwards anything. Nothing
downstream participates, so the target-type cannot affect it.

**The node-side rule the LBC does write is a security group reference, not a
CIDR.** On `sg-00953d82a3d596107`:

```
sgr-04104ba726c8d0b4b  tcp 10080-31307  ref sg-0386a4cd7cdcd1884  elbv2.k8s.aws/targetGroupBinding=shared
```

`sg-0386a4cd7cdcd1884` is `k8s-traffic-bbappsdevstgeksdemoapps-*`, the shared
backend group the LBC attaches to the NLB itself. AWS documents this exact
construction as surviving client-IP preservation:

> Referencing the security group associated with your Network Load Balancer in
> the security groups associated with your targets ensures that your targets
> accept traffic from your Network Load Balancer even if you enable client IP
> preservation for your Network Load Balancer.
> — [load-balancer-security-groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html)

And the private gateway has been the running proof since Day 4: `instance`
targets, `preserve_client_ip.enabled=true`, authorised by that same reference,
serving 200 with the real client IP. The public gateway was the only thing left
on `ip` / `preserve_client_ip=false`.

**The change.** One annotation on `public_gw_eg_proxy`, `ip` → `instance`. Full
plan was `0 to add, 1 to change, 0 to destroy` — no collateral drift. Applied
in 1 s; the LBC then reconciled asynchronously:

| | before | after |
|---|---|---|
| public TGs | `ip`, ports 10080/10443 | `instance`, NodePorts 31771/31955 |
| `preserve_client_ip` | `false` | `true` |
| health check | `traffic-port` | 30959 (`healthCheckNodePort`) |
| public `X-Forwarded-For` | the NLB | `186.122.225.19` (real client) |
| allowlist SG | `186.122.225.19/32` on 80/443 | unchanged |

The node SG rule was recomputed rather than widened as expected: `10080-31307`
became `30385-31955` under a new rule id. It now spans both gateways' NodePorts
and both health-check ports, and dropped 10080/10443 because no `ip` targets
remain — so the rule came out *tighter*, not looser. No manual SG work was
needed at any point.

Both endpoints verified 200 afterwards. The private path is unregressed
(`X-Forwarded-For: 172.18.7.44`, the VPN address). No interruption was observed
on the public hostname during the swap — the LBC brought the new target groups
to healthy before moving the listeners.

**What this costs.** With `instance` + `externalTrafficPolicy: Local`, only
nodes running a public Envoy pod pass the health check; the other two nodes sit
`unhealthy` by design. With `tools` at desired = 1 that is a single point of
failure, now inherited by the public endpoint as well as the private one. It is
the same trade Day 4 accepted deliberately for a disposable cluster — but it is
now the whole ingress surface, so if this cluster ever stops being disposable,
`tools` at desired = 2 plus a `topologySpreadConstraint` covers both gateways
at once.

**What it buys, beyond consistency.** Envoy on the public path now sees the
real client address, which makes an L7 CIDR match (`SecurityPolicy`
`principal.clientCIDRs`) viable without proxy protocol v2. Not adopted — the
security group is cheaper and drops traffic before it reaches a pod — but it is
now a live option for item 4.

Also folded in: three comments that had gone stale on Day 4. The private
gateway's section header still said `target-type=ip`; the public header's
point 2 still justified `ip` with the reasoning refuted above; and the
"trade" paragraph still asked to revisit the timeout tail once nginx was
retired, which S6 already settled (the tail was nginx's, not the target-type's).

## ArgoCD on Envoy Gateway, then upgraded v2.14 → v3.5

First component converted from the dead `private-apps` ingress class to an
HTTPRoute — the conversion the Day-4 note said every re-enabled component would
need. Done in two applies on purpose: get the routing working on the version
already pinned, *then* upgrade, so a routing failure and an upgrade failure
could not be mistaken for each other.

### Three things moved, not one

The chart's Ingress did more than route. Replacing it meant replacing all of it:

- **TLS.** The Ingress asked cert-manager for its own certificate via
  `kubernetes.io/tls-acme`. The gateway's HTTPS listener already terminates
  with the `*.aws.binbash.com.ar` wildcard, so that Certificate is simply gone.
- **The hostname.** It was
  `argocd.demo.devstg.aws.binbash.com.ar` — three labels below the private base
  domain, which a single-label wildcard does **not** cover. Kept as-is it would
  have needed a certificate of its own, which defeats the point of a shared
  gateway. Flattened to `argocd.aws.binbash.com.ar` (new `local.argocd_host`),
  matching how echo-server names itself. Free to change because ArgoCD had been
  `enabled = false`, so no one held the old URL.
- **The backend protocol.** The Ingress carried
  `nginx.ingress.kubernetes.io/backend-protocol: HTTPS` because argocd-server
  runs its own TLS. There is no Gateway API equivalent that is as cheap: the
  options are a `BackendTLSPolicy` (experimental, needs CA config) or telling
  argocd-server to stop doing TLS. Took the second — `configs.params.server.insecure: true`.
  Without it the gateway's cleartext hop gets a 307 to `https://`, which the
  gateway re-terminates, and the browser sees an infinite redirect.

`depends_on` also had to move off `helm_release.ingress_nginx_private` (count 0
since the retirement) onto `kubernetes_manifest.private_gateway_eg`.

### The gRPC caveat

With `server.insecure`, argocd-server multiplexes gRPC and HTTP on one port
over h2c, and Envoy speaks HTTP/1.1 upstream by default — so plain
`argocd login` cannot negotiate gRPC. Two ways out:

- `argocd login argocd.aws.binbash.com.ar --grpc-web`, which tunnels gRPC over
  HTTP/1.1. Verified: a grpc-web probe returns 200.
- `appProtocol: kubernetes.io/h2c` on the server Service port, which Envoy
  Gateway honours to switch the upstream to HTTP/2. Not done — the chart does
  not expose that field, so it would need a patch resource.

Worth knowing for later: the chart has since grown **native Gateway API
support** (`server.httproute.enabled`, plus a separate `server.grpcroute` for
the CLI and `server.backendTLSPolicy` for an HTTPS backend). All three are
flagged EXPERIMENTAL upstream. The hand-written `kubernetes_manifest` was kept
because it was already verified and does not move under us on a chart bump, but
`grpcroute` is the clean fix for the CLI if that ever matters.

### The upgrade: 7.9.1 → 10.2.3 (Argo CD v2.14.11 → v3.5.0)

Three major chart versions. What actually applied to this config:

- **10.0.0** flips `global.networkPolicy.create` false → true, so the chart now
  ships NetworkPolicies. This was the one with real potential to break the
  Envoy path. Left at the upstream default rather than disabled, and verified:
  `networkpolicy/argocd-server` has `ingress: [{}]` — an empty rule, which
  admits every source — so Envoy reaches it. Checked rather than assumed.
- **9.0.0** dropped the `configs.params` defaults from values.yaml but kept the
  override interface, so `server.insecure` still applies as written.
- **9.1.0**'s redis-ha selector breakage does not apply — single-replica redis.
- **8.0.0** is the v2 → v3 jump. Nothing to migrate: no Applications exist, and
  the admin password and both repository credentials are re-rendered from
  Secrets Manager every apply.

Applied in 2m43s, all six pods healthy, route still `Accepted=True
ResolvedRefs=True`.

### Validation

| check | result |
|---|---|
| UI over the gateway | 200, zero redirects, valid TLS off the wildcard (no `-k`) |
| `GET /api/version` | `{"Version":"v3.5.0"}` |
| grpc-web probe | 200 over HTTP/2 |
| `POST /api/v1/session` | 401 — **expected**, see below |
| HTTPRoute status | `Accepted=True ResolvedRefs=True` |
| NetworkPolicy | `argocd-server` ingress `[{}]`, does not block Envoy |

The 401 is a pass, not a failure. The Secrets Manager value is a bcrypt hash
(`$2b$`, 60 chars) — that is what `configs.secret.argocdServerAdminPassword`
expects — and it arrives in `argocd-secret` byte-identical. Sending the hash as
the password had to be rejected. What it proves is the whole path: the POST
reached argocd-server's gRPC `SessionService` through the gateway and was
processed, which the server log confirms.

### Gotcha: don't `dig` a private record before it exists

Polling `argocd.aws.binbash.com.ar` while external-dns was still on its 3-minute
cycle cached the NXDOMAIN, and the `aws.binbash.com.ar` SOA carries TTL 900 — so
the name stayed unresolvable locally for 15 minutes after the record was
actually created, long after `aws route53 list-resource-record-sets` showed a
correct ALIAS to the private NLB. `dig` eventually cleared; macOS `curl` goes
through mDNSResponder and holds it longer (`sudo dscacheutil -flushcache; sudo
killall -HUP mDNSResponder` if you don't want to wait).

Validate with `curl --resolve <host>:443:<nlb-ip>` *first* and only check real
DNS once external-dns has logged the CREATE. Same discipline as the Day-4 dark
launch, for a different reason.

### Not touched

`argocd-image-updater` (chart 0.14.0, latest 1.2.4) and `argo-rollouts` (2.40.8,
latest 2.41.1) are both still `enabled = false`. Left on their pinned versions:
bumping a chart that cannot be deployed and verified is a guess, not an upgrade.
`argo-rollouts` also still renders an Ingress on the dead `private-apps` class
and needs the same HTTPRoute conversion whenever it is turned on.

## The rest of the `private-apps` consumers, converted and upgraded

Backlog item 6, done the same day it was written. Seven hostnames now sit on
`private-gw-eg` and the dead ingress class has no consumers left.

| component | chart before | chart after | app |
|---|---|---|---|
| kube-prometheus-stack | 52.1.0 | 88.1.4 | Prometheus operator v0.93.0 |
| goldilocks | 5.3.0 | 10.5.0 | v4.14.1 |
| uptime-kuma | 2.25.0 | 4.1.0 | 2.3.0 |
| gatus | 1.1.4 (minicloudlabs) | 1.5.0 (**TwiN**) | v5.34.0 |
| argo-rollouts | 2.40.8 | 2.41.1 | v1.9.1 |
| vpa | 0.5.0 | 4.12.5 | 1.6.0 |
| metrics-server | 5.8.4 (**Bitnami**) | 3.13.1 (**kubernetes-sigs**) | 0.8.1 |

**All seven were fresh installs, not upgrades** — every one had been
`enabled = false`. That is what made a 36-major jump on kube-prometheus-stack
tractable: Helm installs the 88.1.4 CRDs from scratch, so none of the chart's
upgrade-path migrations apply. It will not be that easy next time — `helm
upgrade` does not touch CRDs, so the *next* bump needs them applied by hand
first.

### Each route lives with its component

Service names and ports came from `helm template` against the exact pinned
versions, not from upstream docs.

These were first written as a single `for_each` route table in a
`networking-httproutes.tf`, on the argument that "what is reachable on the
private gateway?" should be answerable in one place. **Reverted at Diego's
request** — the repo's convention is that a component owns its file, and a
route belongs next to the `helm_release` it exposes so that turning a component
on or off is one file, not two. Backing it out was seven `moved` blocks and a
`0 to add, 0 to change, 0 to destroy` plan; all seven endpoints re-verified 200
afterwards.

What survives of the consolidation is the part that was actually shared:
`local.private_gw_enabled` and `local.private_gw_parent_refs` in locals.tf,
which also carry the conventions comment every route points back to. Splitting
the resources back out bought something too — each route now depends only on
its own release, where the `for_each` had to depend on all seven because
`for_each` cannot express a per-key dependency.

### Hostnames, flattened

Every component moved from `<app>.demo.devstg.aws.binbash.com.ar` to
`<app>.aws.binbash.com.ar`. Not cosmetic: the wildcard bound to the gateway's
HTTPS listener is `*.aws.binbash.com.ar`, which matches exactly one label. Kept
at three labels deep, all seven would have needed certificates of their own,
which is most of the reason to have a shared gateway in the first place. Free
to change because every one of them was disabled — nobody held the old URLs.

### Four latent bugs surfaced by turning things on

None of these were caused by the conversion; they were sitting in config that
had never been executed.

1. **`metrics-server` 5.8.4 no longer exists.** Bitnami's 2025 catalog change
   purged old versions from the public repo (they survive only under
   `bitnamilegacy`) and moved images behind a subscription. Rather than chase a
   newer Bitnami pin into that licensing question, this moved to the chart the
   metrics-server maintainers publish. Values schema differs: Bitnami took
   `extraArgs` as a map, upstream takes `args` as a list.
   **`kube_state_metrics` (2.2.24) and `node_exporter` (2.2.4) have the same
   dead pins** — left alone deliberately, see the backlog.
2. **Gatus's config could not have worked.** The values used `config.services`;
   Gatus renamed that to `config.endpoints` and v5 rejects the old key. Found
   while switching repos.
3. **Alertmanager was hardcoded `enabled: true`** while its variable was false,
   so it would have rendered with an empty `slack_api_url` — a config it
   refuses to start on. Now gated on the same variable as its route. Its
   Ingress also referenced `clusterissuer-arta-...`, a ClusterIssuer from a
   different project that does not exist here.
4. **argo-rollouts carried `backend-protocol: HTTPS`**, copy-pasted from
   ArgoCD. The rollouts dashboard serves plain HTTP on 3100 and never had TLS.

### Two things that actually broke during the apply

**uptime-kuma timed out and left a failed release.** Its PVC came out with *no*
StorageClass at all — the chart's `volume.storageClassName` defaults to `""`,
and `gp2` here is not annotated as the cluster default. A classless PVC never
binds and never errors; it sits Pending until Helm's 5-minute timeout. Fixed by
naming `gp2` explicitly. Recovering needed `helm uninstall uptime-kuma -n
monitoring-other` first, because a failed release is not in Terraform state but
still owns the name.

Worth generalising: **this cluster has no default StorageClass**, so every
chart that provisions storage must be told which class to use. Verified `gp2`
works at all by binding a probe PVC first — it does, in 20s, through the CSI
migration shim (the class still declares the in-tree
`kubernetes.io/aws-ebs` provisioner, which 1.34 no longer has; the shim
rewrites it onto `ebs.csi.aws.com`).

**Staging the apply was impossible.** The `moved` block for the ArgoCD route
made `-target` illegal — OpenTofu refuses to plan unless the targets cover
every moved instance, and the then-centralised route table depended on all
seven releases, which pulled the whole graph back in. Pre-scaling the `tools`
node group out of band was blocked, so the full apply ran against 5 free pod
slots for 13 new pods.
The cluster-autoscaler handled it: a second `tools` node joined mid-apply and
everything scheduled. Only the two failures above needed intervention.

### Validation

All seven return 200 with valid TLS off the shared wildcard, and each app's
self-redirect lands on its own hostname — which is what proves Grafana's
`root_url` and Prometheus's `externalUrl` were set correctly rather than
defaulting to the Service name:

| host | | redirects to |
|---|---|---|
| argocd | 200 | — |
| rollouts | 200 | `/rollouts/` |
| goldilocks | 200 | `/namespaces` |
| gatus | 200 | — |
| kuma | 200 | `/setup-database` |
| grafana | 200 | `/login` |
| prometheus | 200 | `/query` |

All seven HTTPRoutes report `Accepted=True ResolvedRefs=True`, external-dns
created all seven Route53 records, the three PVCs (20Gi Prometheus, 5Gi
Grafana, 4Gi Kuma) are Bound, `kubectl top nodes` returns data, and
`leverage tofu plan` is clean.

Validation used `curl --resolve` against the private NLB rather than real DNS,
on the lesson from the ArgoCD entry above: querying a private name before
external-dns creates it caches the NXDOMAIN for 15 minutes.

### Not done, deliberately

- **Alertmanager stays off.** Its only receiver needs
  `/notifications/alertmanager` in the shared account and that secret does not
  exist. Enabling it fails the plan at the data source, so it needs the secret
  created first — not something to invent. Its route row is gated on the same
  flag, so nothing dangles.
- **Goldilocks shows an empty dashboard**, and that is upstream behaviour, not
  a defect: it only creates VPA objects for namespaces labelled
  `goldilocks.fairwinds.com/enabled=true`, and none are. Which namespaces to
  profile is a policy call. VPA runs in recommendation-only mode
  (`admissionController: false`), so labelling is read-only and safe.

# Next session — backlog

Ordered by dependency, not priority.

1. ~~**Fix the destroy ordering.**~~ **Done (Day 4)**, though not as written —
   the `depends_on` this item asked for already existed. The fix was a
   `time_sleep.controller_drain` drain gate; see "The finalizer deadlock,
   re-diagnosed". **Still unverified**: it only proves itself on the next full
   teardown, which must run without manual finalizer surgery.

2. ~~**Plan the nginx → Envoy Gateway migration.**~~ **Done (Day 4)** — see
   "nginx → Envoy migration: planned" above. Inventory: echo-server is the only
   live consumer. Cutover approach: dark launch. The client-IP blocker is
   fixed, not deferred. Item 4 turned out **not** to constrain this — nothing
   has a WebACL attached, so it need not be settled first.

3. ~~**Execute the migration.**~~ **Done (Day 4)** — nginx-ingress is gone. See
   "Executing the migration" above for how each step went.

   Still unresolved, not a blocker: Envoy does not emit `X-Real-Ip`,
   `X-Forwarded-Host`, `X-Forwarded-Port` or `X-Scheme`, which nginx
   synthesised. No target-type changes that. Nothing consumes them today, but
   it is now unrecoverable-by-config for anything that later wants them.

4. **Evaluate how to put AWS WAF in front of Envoy.** Reframed on Day 4: this
   is a greenfield decision, not a preservation problem. **No WebACL is
   attached to anything in this stack** — the only traces are IAM permissions
   on the LB controller role and the deployment-excluded
   `security-firewall --` layer. It does not gate item 3. The crux: AWS WAF
   attaches to CloudFront, ALB, API Gateway, AppSync, Cognito, App Runner and
   Verified Access — **not to NLB**, which is what the Envoy Gateways are
   fronted by today. Options to compare: CloudFront with the NLB as a custom
   origin; an ALB in front with a `TargetGroupBinding` onto the Envoy pods;
   provisioning an ALB directly via the LBC's Gateway API support instead of a
   Service of type LoadBalancer; or dropping AWS WAF for an in-Envoy
   equivalent. Each has different consequences for TLS termination and for the
   IP allowlist, which currently lives on the NLB security group.

   Day 5 note: the last option got cheaper. Both gateways now preserve the
   client IP, so an in-Envoy `SecurityPolicy` can match on the real client
   CIDR without proxy protocol v2 — the objection that killed it when this
   item was written no longer holds.

5. **Rewrite the Envoy Gateway implementation docs.** `networking-envoygateway.tf`
   is now ~600 lines and carries most of the reasoning in comments — Day 4's
   target-type rationale made it longer, not shorter. Split the file or move
   the narrative into a layer README, and fold in the visual comparison built
   on Day 3 (published artifact; local copy at
   `~/Desktop/envoy-gateway-vs-nginx.html`). Target: readable without having to
   reconstruct the history from this log.

6. ~~**Convert the remaining `private-apps` consumers to HTTPRoutes.**~~
   **Done (Day 5)** — all five converted and upgraded, plus vpa and
   metrics-server that came along as dependencies. Seven hostnames on
   `private-gw-eg`, each route declared next to its own `helm_release`, and no
   consumers of the dead class left. See "The rest of the `private-apps`
   consumers" above.

   Two follow-ups it produced:

   - **`kube_state_metrics` (bitnami 2.2.24) and `node_exporter` (bitnami
     2.2.4) still carry dead pins** — the same Bitnami catalog purge that
     broke metrics-server. Both are gated off by
     `prometheus.external.dependencies.enabled`, and kube-prometheus-stack
     ships its own of each, so the honest fix is probably to delete these two
     releases rather than repoint them. Decide which.
   - **`argocd-image-updater` (0.14.0, latest 1.2.4) is still pinned and
     disabled.** Left alone on the same reasoning as before: a chart that
     cannot be deployed cannot be verified.

7. **Add a `retry` block to the two `data "http"` CRD downloads.** They fail
   with `TLS handshake timeout` over the VPN and the provider gives up after
   one attempt, which turns into a confusing `0 added` rather than a clean
   error (empty `for_each` via `try(..., "")`). Bites on every re-spin.

8. ~~**Decide the public gateway's target-type.**~~ **Done (Day 5)** — moved to
   `instance`; both gateways are now consistent and both preserve the client
   IP. The premise of this item was wrong: the allowlist lives on the NLB's
   own frontend security group, not on the nodes, and the node-side rule the
   LBC writes is a security group *reference*, which AWS documents as
   surviving client-IP preservation. See "Both gateways on `instance`
   targets" above. Item 4 gains an option from this: Envoy can now match on
   the real client CIDR at L7.
