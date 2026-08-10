# EKS DemoApps — Engineering Journal

Branch: `feature/eks-demoapps-kgateway-private-gateway`
Cluster: `bb-apps-devstg-eks-demoapps` (us-east-1)

This is the decision record for the cluster, not a run log. Routine mechanics —
layer ordering, apply counts, credential refreshes, node scheduling — are left
out; see `README.md` for orchestration and `k8s-components/README.md` for the
ingress topology.

**What this cluster is for.** It models a production topology being migrated
off nginx-ingress, so that the migration can be rehearsed here rather than
there. That topology is:

| | modelled setup | here |
|---|---|---|
| public | ALB + ACM + WAF → nginx pods → app | ALB + ACM (+ WAF, pending) → **Envoy** → app |
| private | NLB → nginx pods → app | NLB → **Envoy** → app |
| DNS | external-dns private + public, on Ingress | same, on Ingress + HTTPRoute |
| certs | cert-manager per Ingress | one wildcard per Gateway listener |

The perimeter is meant to stay recognisable; the data plane is what changes.
**Reintroducing nginx here is never an option** — replacing it is the point.

**Current state (2026-08-10).** Up. EKS 1.34.9 on AL2023 with spot nodes,
`echo-server` the only workload, both public and private paths on Envoy Gateway.
`network/terraform.tfvars` is at `vpc_enable_nat_gateway = true` while it runs.

**No WAF is deployed right now.** It was built, attached, verified and then
taken back down the same day: `waf_enabled = false`, the association removed by
hand, and `security-firewall` destroyed (3 resources, clean first pass, because
the disassociation came first). The code is all in place, so re-attaching is
applying that layer and flipping the flag. Everything learned doing it is kept
below — the point of the exercise was the rehearsal, not leaving it running.

---

## Timeline

| Day | Date | Milestone |
|---|---|---|
| 1 | 2026-05-04 | Cluster stood up. nginx-ingress serving `echo-server`. kgateway added in parallel as a second data plane. |
| 2 | 2026-05-05 | Node-group hardening. Envoy Gateway added as a third parallel data plane. HTTP→HTTPS redirect solved at the Gateway level. |
| 3 | 2026-08-03 | Three-way benchmark → **Envoy Gateway chosen**; kgateway removed. Public gateway with IP allowlist added. Client-IP defect found on the EG path. |
| 4 | 2026-08-04 | Client-IP defect fixed; **nginx-ingress retired**. Destroy-ordering fixed with a drain gate. |
| 5 | 2026-08-04 | Both gateways unified on `instance` targets. All remaining components converted from the dead ingress class to HTTPRoutes and upgraded. |
| 6 | 2026-08-05 | Teardown verified the drain gate. Re-spin, then **component set trimmed** to echo-server. CRD bundles **vendored**. |
| 7 | 2026-08-06 | **ALB in front of the public Envoy Gateway**, replacing its NLB. Per-route IP filtering moved into Envoy; perimeter opened. |
| 8 | 2026-08-10 | Re-spun from scratch. **AWS WAF attached to the ALB, verified, then detached and destroyed** — backlog item 4 closed. **Managed add-ons caught up to 1.34**, `vpc-cni` stepwise. **nginx-ingress removed from the code.** |

---

## Architecture decisions

### Envoy Gateway is the data plane; nginx and kgateway are gone

Three implementations ran in parallel before choosing (`loadtest/test-results.md`
has the numbers). The decision hinged on a benchmark result that reversed the
prior reading: **scenario S6 — the controlled test, both data planes on
identical `instance`-target plumbing — showed Envoy at zero failures over 450k
requests against nginx's 425 (0.09%).** The long-standing "nginx is faster"
ordering had been an artifact of comparing different NLB target types, and the
two are indistinguishable on equal footing.

Removing kgateway required breaking a coupling first: its file owned the
*shared* upstream Gateway API CRDs, which Envoy Gateway also consumes. Deleting
it naively would have destroyed `Gateway`/`HTTPRoute`/`GatewayClass` out from
under EG. They were extracted into `networking-gateway-api.tf` with resource
addresses preserved, so the move was a no-diff refactor.

Removal leftover worth generalising: `helm uninstall` left `GatewayClass/kgateway`
behind, carrying no helm metadata — the *controller* creates it at runtime, so
helm never owned it. **Controller-created, cluster-scoped objects on shared CRDs
do not come out with terraform or helm.**

**nginx-ingress left the code on day 8**, having left the cluster on day 4. It
had been sitting at `enabled = false` since, which is what made the removal
cheap: nothing nginx-shaped was in state, so deleting it is a pure code change
and `tofu plan` returning `No changes` *is* the verification. Gone:
`helm_release.ingress_nginx_private`, `kubernetes_namespace.ingress_nginx`,
`kubernetes_ingress_v1.nginx_apps`, the `nginx_controller` flag and its
`terraform.tfvars` block, the `nginx_ingress_tags_*` locals and
`chart-values/ingress-nginx.yaml`.

**traefik stays**, by decision — it was never used here either, but it is not
what this cluster is about. Removing nginx from beside it did require untangling
them: the two counts encoded a mutual exclusion (`nginx && !traefik` against
`!nginx && traefik`), which collapses to plain `traefik.enabled` now that there
is nothing to be exclusive with. `var.ingress.apps_ingress` and
`local.load_balancer_attributes` survive for the same reason — it is
`traefik_apps`, not the Envoy ALB, that consumes them. The Envoy Ingress has its
own tags local and does not set `load-balancer-attributes` at all. If traefik
ever goes, all of that goes with it.

`local.alb_ingress_to_nginx_ingress_tags_*` was renamed to
`..._to_private_ingress_tags_*` — traefik inherited it, and a local named after
a component that no longer exists is exactly the residue a removal is for.

What deliberately did **not** change: every historical mention of nginx in this
journal, `k8s-components/README.md`, `cicd-argo.tf`, `networking-envoygateway.tf`,
`echo_server.tf` and `loadtest/`. The `whitelist-source-range` annotation this
cluster set out to translate, the 308 redirect Gateway API rejects, the
benchmark that settled it — deleting the code is not a reason to delete the
reasoning, and this file is a decision record.

### The client IP, and a piece of received wisdom that was wrong

EG was initially on `ip` target-type (NLB → pod ENI). For `ip` target groups on
TCP, AWS defaults `preserve_client_ip` to false, so Envoy saw the NLB as the
client and `X-Forwarded-For` was useless — blinding rate limiting, allow-lists,
audit and geo.

Fixed by moving to `instance` targets, one annotation. On `instance` groups AWS
preserves the source IP and it **cannot** be disabled, so target-type alone is
the whole fix — `preserve_client_ip` is not a companion setting. It does require
`externalTrafficPolicy: Local`, which EG already defaults to.

This was expected to cost latency, since `ip` was believed to be why EG was
fast. S6 proved otherwise, so nothing was traded away.

Day 5 then unified the public gateway onto `instance` too, after settling an
assumption that had blocked it: that preserving client IP would break the
allowlist. It does not, for two independent reasons. **The allowlist lives on
the NLB's own frontend security group**, evaluated before the NLB forwards
anything — nothing downstream participates. And **the node-side rule the LBC
writes is a security group *reference*, not a CIDR**, which AWS documents as
surviving client-IP preservation. The node SG rule came out *tighter* after the
change, not looser.

Cost of `instance` + `Local`: only nodes running an Envoy pod pass the health
check. With `tools` at desired = 1 that is a single point of failure across the
whole ingress surface. Accepted deliberately for a disposable cluster; if that
ever changes, `tools` at desired = 2 plus a `topologySpreadConstraint` covers
both gateways at once.

### The public gateway's allowlist

Three decisions worth keeping:

1. **Enforced at the NLB security group, not in Envoy.** (When written, the
   `ip` target-type made an L7 CIDR match impossible. Since Day 5 an in-Envoy
   `SecurityPolicy` *is* viable — but the SG is still cheaper, dropping traffic
   before it reaches a pod.)
2. **The CIDR list is a gitignored `allowlist.local.auto.tfvars`**, top-level
   rather than a field of `envoy_gateway` because tfvars cannot merge into an
   object variable. A `precondition` fails the plan when it is empty, since the
   LBC would otherwise default the SG to `0.0.0.0/0`. **The file is required** —
   recreate from the `.example` if the tree is cleaned.
3. **The public HTTPS listener uses a label Selector, not `from: All`.** A
   namespace must carry `gateway.binbash.com.ar/public-exposure=allowed`, so
   writing an HTTPRoute is not by itself enough to reach the internet.

EG resolves `EnvoyProxy` through `GatewayClass.parametersRef` rather than per
Gateway, so the public data plane needed its own GatewayClass. Naming is
asymmetric as a result — `gatewayClassName` is immutable, and renaming the
private class would have recreated its Gateway and NLB.

### Hostnames are one label under the base domain

Everything moved from `<app>.demo.devstg.aws.binbash.com.ar` to
`<app>.aws.binbash.com.ar`. Not cosmetic: the wildcard bound to the HTTPS
listener is `*.aws.binbash.com.ar`, which matches exactly one label. Kept three
deep, every component would have needed its own certificate — most of the reason
to have a shared gateway in the first place.

The private zone has no public NS delegation, so `_acme-challenge` queries climb
to the public zone where cert-manager can write. That fall-through is what lets
a private-only zone pass ACME DNS01.

### A component owns its file

The seven HTTPRoutes were first written as a single `for_each` table, on the
argument that "what is reachable on the private gateway?" should be answerable
in one place. **Reverted at Diego's request**: the repo's convention is that a
component owns its file, and a route belongs next to the `helm_release` it
exposes, so turning a component on or off is one file rather than two.

The split bought something beyond convention — each route now depends only on
its own release, where a `for_each` had to depend on all seven, because
`for_each` cannot express a per-key dependency. What survives of the
consolidation is the genuinely shared part: `local.private_gw_enabled` and
`local.private_gw_parent_refs`.

### CRDs bypass helm, and are vendored

The Envoy Gateway CRD chart archive exceeds **etcd's 1 MB-per-Secret limit**
when helm stores the release (the `EnvoyProxy` CRD alone is 1.2 MB), so both CRD
sets are applied as individual `kubernetes_manifest` resources instead. The main
chart needs `skip_crds = true` for the same reason.

Since Day 6 the bundles are **vendored** under `k8s-components/crds/` rather
than fetched from GitHub at plan time. The motivating argument is not the
download flakiness that prompted it: **a `for_each` built from a network read
can go empty for reasons outside the config, and empty means destroy** — which
for these keys would take every Gateway and HTTPRoute in the cluster with it.
Secondarily, a version tag pins a URL and not a payload, since GitHub release
assets are mutable.

The one risk vendoring introduces — chart and CRDs drifting apart — is closed by
putting the version in the filename and building the path from the same variable
that drives the chart, so a bump that forgets to re-vendor fails at plan time on
a missing file. Verified. Re-vendoring is documented in `k8s-components/README.md`.

### The public path runs on an ALB, not an NLB

Selected by `envoy_gateway.public_gateway.frontend`, `"nlb"` or `"alb"`. The
two are mutually exclusive and everything hangs off that one word, so the
rollback is a single-token edit; the NLB path is gated off rather than deleted.
Under `alb` the Gateway's Service drops to ClusterIP — with `envoyService.name`
pinned, since EG otherwise derives a hash-suffixed name the Ingress cannot
reference — and an Ingress asks the LBC for an ALB in front of it.

This was validated as a POC before being adopted. Four things came out of it
that were not obvious beforehand:

**An ALB health check against Envoy 404s.** Envoy has no `/healthz` to offer:
a request matching no route returns 404, so the default `/` fails the check on
a perfectly healthy gateway. Not an Envoy Gateway defect — every Envoy-based
ingress hits it, Istio ships a dedicated endpoint on `:15021` and kgateway's
own AWS ALB guide answers it with a route returning a fixed 200. Solved the
same way, via `HTTPRouteFilter.directResponse`.

Deliberately *not* Envoy's readiness endpoint on `:19001/ready`: readiness
reports that the process is up and stays green while the listener is broken,
the certificate failed to load, or the Gateway never reached `Programmed`. The
`/healthz` route traverses the listener and the route engine, so a passing
check means the thing that serves traffic works.

A pleasant accident: requesting `/healthz` on a real hostname is answered by
the *application*, not the fixed response, because Gateway API ranks hostname
specificity above path specificity. The ALB's check arrives with `Host: <ip>`,
matches no hostname, and falls through to the fixed 200. Applications keep
their own `/healthz`.

**`ClientTrafficPolicy` with `numTrustedHops: 1` is load-bearing.** Without it
Envoy treats the ALB as the client: it overwrites `X-Forwarded-Proto` with
`http` — so a backend building self-referential URLs emits `http://` links and
one redirecting to its canonical URL loops — and reports the ALB's address as
the origin, which would make any CIDR match hit everything or nothing. One
field covers both; upstream documents `numTrustedHops` as deciding the origin
address *and* whether `x-forwarded-proto` is trusted.

Counting from the right of XFF is what makes it safe, and it was tested rather
than assumed: a client-supplied `X-Forwarded-For: 1.2.3.4` still resolves to
the address AWS observed, because the ALB appends that to the right of the
forgery. **The private Gateway must not get this policy** — nothing sits in
front of it, and trusting a client-supplied XFF there would let anyone claim
any source IP. Side effect worth knowing: `X-Envoy-External-Address` disappears
on the ALB path.

**Public HTTPRoutes must be hidden from external-dns.** Once the Gateway's
Service is ClusterIP its address is a cluster-internal IP, and external-dns
watching `gateway-httproute` publishes *that* into the public zone. Observed
live before the annotation was applied:
`echo-server.binbash.com.ar → 10.100.194.250`. The record comes from the ALB's
Ingress instead, and ownership transferred between the two sources in one sync
cycle.

**`group.name` is what separates two ALBs from one.** The LBC merges every
Ingress sharing a group onto a single balancer, so the Envoy lane needs its own
(`apps-eg`, against the pre-existing `apps`). The name is baked into the ALB's
name and tags, so changing it later recreates the balancer.

### Access control is per-application, and the perimeter is open

The modelled setup filters public-vs-restricted with an nginx
`whitelist-source-range` annotation — at the application, not at the perimeter.
The Gateway API translation is a `SecurityPolicy` with
`authorization.rules[].principal.clientCIDRs` attached to the app's own
HTTPRoute.

Envoy policies can only target resources in their own namespace, which forces
the policy to live in k8s-workloads next to the route. That constraint turned
out to point at the right answer: the annotation being replaced carries a value
that belongs to the application. So there are two lists on purpose —
`envoy_gateway_public_allowed_cidrs` (who may reach the cluster, on the load
balancer) and `echo_server_public_allowed_cidrs` (who may reach this app,
inside Envoy). They hold the same value only while there is one operator.

`defaultAction: Deny` rather than relying on the absence of a match: a rule set
that only lists allows, with a permissive default, fails open on a typo.

With that in place the ALB was opened to `0.0.0.0/0`, matching the modelled
setup. The perimeter allowlist had always been a stand-in, and keeping it
closed would be a second place to forget as well as a mask — a route whose
policy is broken looks fine from inside the allowlist. `open_to_internet`
exists so that "open" is written down: the same state was reachable by leaving
the CIDR list empty, which is indistinguishable from having forgotten to fill
it in. **Empty means mistake; the flag means decision.**

Verified with the perimeter open, which is the configuration where a broken
policy is actually exposed: allowed CIDR → 200, `192.0.2.0/24` → 403
`RBAC: access denied`, restored → 200.

### Destroy ordering: a drain gate, not `depends_on`

The first teardown deadlocked with Services stuck in `Terminating` holding
`service.k8s.aws/resources`, and the diagnosis written at the time — missing
`depends_on` between controllers and the objects they manage — **was wrong**.
Those `depends_on` were already in place and predated the deadlock.

The real mechanism is asynchronous garbage collection. Deleting a `Gateway`
returns as soon as the CR is gone; the derived `Service` is collected by the EG
controller seconds later, and only then does the LBC delete the NLB and strip
its finalizer. Terraform waits for none of it and destroys the controllers
mid-cleanup. **No `depends_on` can express "wait for a controller to finish
reconciling."**

The fix is `time_sleep.controller_drain` (180s) in `networking-ingress.tf`. The
dependency direction is inverted from what reads naturally: the sleep depends on
the *controllers*, and the managed objects depend on the *sleep*, so the
reverse-order destroy yields `objects → wait → controllers`.

**Verified on the Day 5 → 6 teardown**: all 50 resources destroyed in one pass,
no `context deadline exceeded`, no namespace stuck `Terminating`, no finalizer
surgery.

### DNS cutovers: hide the old backend, do not delete it

The nginx → Envoy cutover bundled "stop serving the old path" into the same
apply that moved DNS, which left the hostname 404ing for up to one sync cycle
plus the ALIAS TTL. Calling that inherent to DNS-based cutovers — as this
journal first did — was wrong.

The fix is to invert *which* object is hidden from external-dns: annotate the
**old** backend with `external-dns.alpha.kubernetes.io/controller: none` and
leave it running. nginx does not read that annotation, so it keeps serving,
while external-dns stops seeing it and the new route becomes the only source for
the name. DNS repoints while both data planes answer. Only once propagation is
complete is the old object deleted.

Correct order: dark-launch on a transient hidden route → hostname onto the real
route *plus* the ignore annotation on the old one → wait a sync + TTL and verify
over real DNS → delete. The repoint itself contributes nothing to the gap:
external-dns issues an UPSERT and Route53 changes atomically, so a resolver sees
the old target or the new one, never NXDOMAIN.

Note the records are ALIAS to an NLB and Route53 imposes the target's 60 s TTL
on ALIAS, so it cannot be pre-lowered to speed up a flip. A *percentage* canary
would need Route53 weighted records via external-dns `set-identifier` — a
different mechanism.

### Argo CD needed three things replaced, not one

Converting it off the Ingress meant replacing everything the Ingress did: the
cert-manager `Certificate` (the gateway's wildcard already terminates), the
hostname (flattened, see above), and the backend protocol. That last one has no
cheap Gateway API equivalent — the options are an experimental `BackendTLSPolicy`
or telling argocd-server to stop doing TLS. Took the second
(`configs.params.server.insecure: true`); without it the gateway's cleartext hop
gets a 307 and the browser sees an infinite redirect.

Consequence: argocd-server multiplexes gRPC and HTTP over h2c while Envoy speaks
HTTP/1.1 upstream, so plain `argocd login` cannot negotiate gRPC. Use
`--grpc-web`. The clean fix, if it ever matters, is `appProtocol:
kubernetes.io/h2c` on the Service port — the chart does not expose it, so it
needs a patch resource. The chart has since grown native Gateway API support
(`server.httproute`, `server.grpcroute`, `server.backendTLSPolicy`), all flagged
EXPERIMENTAL upstream.

### Latent bugs surfaced by turning components on

None were caused by the HTTPRoute conversion; they were sitting in config that
had never been executed.

- **Bitnami's 2025 catalog purge** removed `metrics-server` 5.8.4 from the
  public repo and moved images behind a subscription. Moved to the
  kubernetes-sigs chart (values schema differs: `extraArgs` map → `args` list).
  `kube_state_metrics` and `node_exporter` carry the same dead pins.
- **Gatus's config could never have worked** — `config.services` was renamed to
  `config.endpoints` and v5 rejects the old key.
- **Alertmanager was hardcoded `enabled: true`** while its variable was false,
  so it would have rendered with an empty `slack_api_url`, which it refuses to
  start on. Its Ingress also referenced a ClusterIssuer from another project.
- **argo-rollouts carried `backend-protocol: HTTPS`**, copy-pasted from Argo CD;
  its dashboard serves plain HTTP.

### Component set trimmed (Day 6)

kube-prometheus-stack — **including Grafana**, whose route is gated on the same
flag — plus goldilocks, VPA, metrics-server, uptime-kuma, gatus, Argo CD and
Argo Rollouts were all disabled. 19 resources destroyed in one clean pass, no
orphaned PVCs, and external-dns cleaned all seven Route53 records on its own
(it outlives the routes here, so the delete-routes-first discipline below did
not apply).

`argocd.rollouts.enabled` is evaluated **independently** of `argocd.enabled`, so
both flags have to move together or Rollouts installs with no Argo CD beside it.

Deliberately still off: **Alertmanager** (needs `/notifications/alertmanager` in
the shared account, which does not exist — enabling it fails the plan at the
data source) and **argocd-image-updater** (a chart that cannot be deployed
cannot be verified, so bumping its pin would be a guess).

---

### The add-ons were left three minors behind, and kube-proxy is now unpinned

The 1.34 upgrade moved the control plane and the nodes and left every managed
add-on in `addons/locals.tf` at its 1.31-era pin. EKS surfaced it as two
UPGRADE_READINESS insights in ERROR: `kube-proxy version skew` ("three or more
versions behind the cluster control plane version") and `EKS add-on version
compatibility`. The first is not cosmetic — that is outside the supported skew.

`kube-proxy` lost its `addon_version` entirely. `addons.tf` already falls
through to `data.aws_eks_addon_version`, which resolves against the cluster's
own Kubernetes version, so the version now follows the cluster by construction.
Its supported skew is *defined* relative to the control plane, which makes a pin
a standing invitation to forget it on the next upgrade — precisely what
happened. The other three keep explicit pins: they have release cycles of their
own, so pinning buys reproducibility rather than costing correctness.

`vpc-cni` was upgraded **one minor at a time** — 1.18.5 → 1.19.6 → 1.20.5 →
1.21.2 → 1.22.4 — rather than in one jump, per AWS's guidance for the CNI. Each
step is its own `-target`ed apply followed by the same check: the `aws-node`
DaemonSet rolled, the add-on `ACTIVE` with no health issues, a freshly created
pod getting an IP and resolving both cluster and public DNS and reaching the
internet, and both echo-server hostnames still answering 200. A fresh pod is
the load-bearing part — an existing pod keeps its networking across an
`aws-node` restart, so only a new one exercises the upgraded CNI.

The in-place stepwise path was chosen over simply fixing the pins and letting
the next re-spin install them clean. Fixing the pins is what this cluster
needs; rehearsing the upgrade is what the migration it models needs.

**The insights lag, and they are not about today.** They are evaluated against
the *next* Kubernetes version — `kubernetesVersion: 1.35` on this cluster, so
the `compatibleVersions` they report are floors for 1.35 and copying them as
pins would leave you a version behind again. They also refresh on a schedule of
their own (roughly daily) with no API to force it, so both stayed ERROR after
the upgrade with a `lastRefreshTime` from before it. Verify by comparing the
installed versions against the reported floors rather than waiting.

---

## Recurring gotchas

**`k8s-components` needs a two-stage apply on a fresh cluster.**
`kubernetes_manifest` validates against the live API at *plan* time, so
`EnvoyProxy` manifests fail before their CRDs exist. Stage 1 targets the two CRD
manifests plus the EG controller; the full plan is clean afterwards. Note a
standalone `tofu plan` can report clean while the *apply's own* plan phase
fails — a green plan is not proof.

**The same validation blocks destroys.** Once CRDs are gone, `tofu destroy`
fails on manifests no longer in state. Work around with `-target`, or set the
layer's `enabled` toggles to false first.

**An empty map is not an empty map.** The kubernetes provider serialises `{}`
as `null`, which a CRD requiring an object rejects
(`must be of type object: "null"`). To say "no annotations", omit the key —
`merge()` a conditional fragment in rather than setting the field to `{}`.

**Prove an allowlist with a request from a different source, not by editing the
list.** A 200 only shows the request arrived, not that anything was
discriminated — if the policy were missing entirely the operator would still
get 200.

The cheap way to get a second vantage point is **from inside the cluster**: a
throwaway pod egresses through the NAT Gateway, so its public address is the
NAT EIP, which is by construction not on any operator allowlist.

```
kubectl run probe --rm -i --restart=Never --image=curlimages/curl:8.11.1 \
  --command -- curl -s -m 25 -o /dev/null -w '%{http_code}\n' \
  https://echo-server.binbash.com.ar/
```

Verified 2026-08-10: `403` with the body `RBAC: access denied` from the pod
against `200` from the operator's machine. Same URL, same config, only the
source address differs, so the SecurityPolicy is genuinely discriminating on
source IP. The body matters — `RBAC: access denied` is Envoy's RBAC filter
specifically, where the ALB would have refused the connection and a routing
miss would be 404.

It also proves something the config-editing version cannot: that
`numTrustedHops` extracts the origin address correctly. If Envoy were reading
the ALB as the client, both requests would present the *same* address and land
the same way. That they diverge is the proof.

The older approach — swap the real CIDR for `192.0.2.0/24` (TEST-NET), expect a
denial, restore — is still the only way to test a CIDR *boundary*, since the
source address is not selectable here. But it mutates config to test behaviour,
and a failed apply mid-swap leaves the endpoint either locked or open, so
prefer the pod. Whichever is used, `curl --no-keepalive`: an established
connection survives a rule change and reads as a false pass. And note `WebFetch`
egresses from the operator's own machine, so it is not a second vantage point
at all.

**A WAF in COUNT needs the same treatment, and the logs supply it.** Every
request returns 200 whether or not a rule matched, so response codes prove
nothing at all. Send a probe that *should* match — `?q=1' OR '1'='1` trips
`SQLi_QUERYARGUMENTS` — and read `aws-waf-logs-wafv2-apps`:
`nonTerminatingMatchingRules` carries the COUNT, and the rule group's
`terminatingRule` shows the action it would have taken in enforce mode. An
empty log is the real failure signal, because it means the WebACL is
associated but not in the request path.

**`create_sg = false` is not `create = false`.** On
`terraform-aws-security-group`, the first suppresses the group and leaves its
rules in the graph, where each resolves `security_group_id` to null and fails
the plan with `Missing required argument`. Pass both. This sat latent in
`security-firewall` for as long as its demo ALB was switched on, and surfaced
the moment it was switched off.

**A WebACL cannot be deleted while it is associated.** The association belongs
to the ALB, which belongs to the Ingress in `k8s-components` — so that layer
(or at least `kubernetes_ingress_v1.envoy_apps`) has to go before
`security-firewall`. Same shape as the drain gate: the thing holding the
reference is not the thing that owns it in Terraform.

**The Load Balancer Controller attaches a WebACL but never detaches one.**
Confirmed against v2.13.4, both ways: removing `wafv2-acl-arn` from the Ingress
leaves the WebACL associated, and so does setting it to the empty string. The
controller acts on a non-empty ARN and otherwise has no opinion — an absent or
empty annotation means "not mine to manage", not "remove it". The apply reports
success and the config reads as WAF-off while every request is still being
inspected, which is the dangerous half of this: the failure is silent and in
the *safe* direction on the way in, and in the *misleading* direction on the
way out.

Detaching is therefore a separate act:
`aws wafv2 disassociate-web-acl --resource-arn <alb-arn>`. Nothing in Terraform
state represents the association, so this creates no drift — it is the mirror
of how the association was made. Verify with `get-web-acl-for-resource`, which
returns an empty result once it is gone; do not trust the plan.

**Do not `dig` a hostname before external-dns creates it.** One early query
caches the NXDOMAIN. The private zone's SOA gives 15 minutes; `binbash.com.ar`
carries `minimum=86400`, so **24 hours** on a public hostname. Validate with
`curl --resolve <host>:443:<nlb-ip>` and check real DNS only after external-dns
logs the CREATE. Public resolvers are unaffected; locally,
`sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder`.
external-dns syncs every **3 minutes**.

**The AWS LBC webhook race — preventable, not just recoverable.** On a first
apply the LBC's mutating webhook is registered before its pods are ready, so any
release creating a Service fails with `no endpoints available for service
"aws-load-balancer-webhook-service"`. Hit on Day 1, 2, 3 and 6.

**Prevent it by giving the LBC an apply of its own**, between the CRD stage and
the full apply:

```
leverage tofu apply -target=helm_release.alb_ingress
kubectl -n alb-ingress get pods      # both Running before continuing
leverage tofu apply
```

Day 8 stood the whole stack up this way and the race did not fire — 23 of 23
resources on the first pass. It costs one extra targeted apply and is the same
two-stage shape the CRDs already force, so it may as well be the default order.

If it does fire: wait for the LBC pods, then retry. **A helm release that failed
is not in Terraform state but still owns its name**, so recovery needs
`helm uninstall <name> -n <ns>` first. Same family as the drain gate: Terraform
waits for a release to finish, not for its controller to be *ready*.

**This cluster has no default StorageClass.** `gp2` exists but is not annotated
as default, and a classless PVC never binds and never errors — it sits Pending
until Helm times out. Every chart that provisions storage must name `gp2`
explicitly. (`gp2` still declares the in-tree provisioner, which 1.34 no longer
ships; the CSI migration shim rewrites it onto `ebs.csi.aws.com`.)

**`leverage tofu` exit code is not trustworthy** — it has returned exit 0 on a
failed apply, including one where zero resources were created. Grep the output
for `Apply complete!` / `^Error:` instead, and strip ANSI first since it
colourises even when redirected.

**NLB targets read `unhealthy` for the first few minutes** after a gateway is
created, and an internet-facing NLB converges slower than an internal one. That
asymmetry looks exactly like a security-group fault. Re-check before
investigating. Separately, with `instance` + `Local`, nodes *not* running an
Envoy pod are `unhealthy` by design.

**Security groups are stateful**, so an established keep-alive connection keeps
working after a rule tightens. Proving an allowlist requires an A/B on the list
itself — real CIDR → 200, TEST-NET → timeout, restore → 200 — with
`curl --no-keepalive`. Note `WebFetch` egresses from the operator's own machine
and cannot serve as an external vantage point.

**When refactoring a resource between two helm releases under terraform**, stage
the apply so the *donating* release upgrades before the *adopting* one creates.
Otherwise helm's diff-against-v1-manifest deletes the resource right after
adoption.

**`moved` blocks make `-target` illegal** until they are applied — OpenTofu
refuses to plan unless the targets cover every moved instance.

---

## Notes on individual components

**Goldilocks** only creates VPA objects for namespaces labelled
`goldilocks.fairwinds.com/enabled=true`, so an empty dashboard is upstream
behaviour, not a defect. It ran recommendation-only
(`admissionController: false`), never rewriting requests. Its verdict on
echo-server — cpu 10m→15m, memory 32Mi→**100Mi** against a 64Mi limit — was
filed **won't-fix**: echo-server is a throwaway test app and re-specing it would
invalidate the benchmark history. (Removed on Day 6 along with VPA and
metrics-server, its only consumers.)

**kube-prometheus-stack** went 52.1.0 → 88.1.4 as a *fresh install*, not an
upgrade, which is what made a 36-major jump tractable — Helm installs the new
CRDs from scratch, so none of the chart's upgrade-path migrations applied. It
will not be that easy next time: `helm upgrade` does not touch CRDs, so the next
bump needs them applied by hand first.

**echo-server** is the only workload, and its namespace had to be brought under
terraform — it was referenced by string on the theory that it survived an old
helm release, which holds only until the cluster is rebuilt, which this layer
does routinely.

Migration note for anything moving off nginx: nginx synthesises `X-Real-Ip`,
`X-Forwarded-Host`, `X-Forwarded-Port` and `X-Scheme`; Envoy Gateway does not.
Closed as won't-fix here since nothing consumed them. Gateway API also permits
only 301/302 redirects, rejecting nginx's default 308.

---

## Cost cycle

`vpc_enable_nat_gateway` in `network/terraform.tfvars` is the down/up switch —
`false` to tear down, `true` before re-running `cluster`. The VPC is kept across
teardowns for a fast re-spin. The committed default is `false`, deliberately, so
the flip to `true` is a local working change and not something to commit.

Before destroying `k8s-workloads` / `k8s-components`, delete the DNS-producing
objects first and let external-dns clear the records while it is still alive.
Not fatal if skipped — policy `sync` plus a stable `txtOwnerId` means the next
re-spin adopts and deletes them — but it keeps the zone honest in between.

**Which objects those are changed with the ALB.** The public record is now
published by `kubernetes_ingress_v1.envoy_apps`, not by the HTTPRoute, so that
Ingress is what gets the targeted destroy first. The routes are hidden from
external-dns and produce nothing.

The 2026-08-06 teardown ran clean on the first pass at every layer —
`k8s-workloads` 6, `k8s-components` 40 in a single pass with no finalizer
surgery (the drain gate covers the ALB as well as the NLBs), `addons` 4,
`identities` 37, `cluster` 50, `network` 3 with the VPC kept. Afterwards: zero
EKS clusters, load balancers, target groups, instances, NAT gateways, EIPs, EBS
volumes or `k8s-*`/`eks-*` security groups.

One piece of litter survived: a TXT record `a-echo-server.binbash.com.ar` whose
external-dns ownership label still names
`httproute/echo-server/echo-server-eg-public`. It is a leftover of the
ownership transfer from HTTPRoute to Ingress — the registry record for the old
owner was never reclaimed. Inert (there is no A record beside it) and the owner
ID matches, so the next re-spin should adopt it, but it is worth knowing it is
there before diagnosing anything odd about that hostname.

---

## Backlog

**All of 1-8 are done.** Destroy ordering (drain gate, verified), the nginx →
Envoy migration (planned and executed), the Envoy docs rewrite, the full
HTTPRoute conversion, both gateways on `instance` targets, the CRD download
fix — superseded by vendoring, which removed the `data "http"` blocks entirely
— and, as of 2026-08-10, the WAF.

**4. Put AWS WAF in front of Envoy. Done 2026-08-10.**

The item was originally framed around a constraint: AWS WAF attaches to
CloudFront, ALB, API Gateway, AppSync, Cognito, App Runner and Verified Access
— **not to NLB**, which was what fronted both Gateways. That made it look like
a choice between CloudFront, an ALB, or dropping AWS WAF for an in-Envoy
equivalent.

The framing was wrong, and clarifying the purpose of this cluster dissolved it.
The setup being modelled *already runs ALB + WAF*, so the ALB was never the
obstacle to route around — it was the target. CloudFront and Cloudflare were
ruled out, `ext_authz` rejected on the grounds that body inspection needs
buffering and without bodies a WAF misses half of what it is for, and
Coraza-on-Wasm kept only as a side experiment (EG 1.7.2 does support
`EnvoyExtensionPolicy` with `wasm`, verified against the vendored CRDs).

What it took, once the ALB was there:

- **`apps-devstg/us-east-1/security-firewall` renamed out of its ` --`
  exclusion** and applied — three resources: the WebACL, its logging
  configuration and the `aws-waf-logs-wafv2-apps` log group. `infracost.yml`
  needed the path updated to match, and the rename puts the layer into
  Atlantis autodiscover.
- **The association is made by the Load Balancer Controller**, from
  `alb.ingress.kubernetes.io/wafv2-acl-arn` on `kubernetes_ingress_v1.envoy_apps`,
  not by a `wafv2_web_acl_association` resource. Nothing that plans before the
  ALB exists can know its ARN, and the ARN changes on every re-spin — and this
  is also how the modelled setup attaches its WAF. The firewall layer therefore
  owns the WebACL and never an association; `alb_waf_example.enabled` goes to
  `false` so it stops provisioning a throwaway ALB to associate with.
  **It is one-way** — the controller attaches but never detaches; see the
  gotcha below before trusting `waf_enabled = false`.
- **The ARN crosses layers by remote state**, behind
  `envoy_gateway.public_gateway.waf_enabled`, with the data source itself
  `count`ed so `k8s-components` still plans standalone with the WAF off. A
  second `validation` rejects `waf_enabled` with `frontend = "nlb"` rather than
  ignoring it.
- **The LBC's IAM role already held `wafv2:AssociateWebACL`** — verified, not
  assumed. Nothing to add in `identities`.

**Two managed rule groups were dropped rather than counted.**
`AWSManagedRulesBotControlRuleSet`, because its `CategoryHttpLibrary` signal
targets exactly the non-browser clients every check against this cluster uses,
and `AWSManagedRulesATPRuleSet`, because it was aimed at
`login_path = "/api/1/signin"`, which nothing here serves. Each bills about
$10/month on top of the WebACL, so both were paying to protect nothing while
threatening to break the tests. The remaining six run at priorities 0-5.

**Everything starts in COUNT.** The WebACL observes and logs without blocking;
a rule is promoted to `block` only after its counted requests show no
legitimate traffic caught. Verified live, and the log entry is the whole point:

```
action: ALLOW, terminatingRuleId: Default_Action
nonTerminatingMatchingRules: [ AWSManagedRulesSQLiRuleSet → COUNT,
  SQL_INJECTION in ALL_QUERY_ARGS, field "q" ]
ruleGroupList: SQLi → terminatingRule { SQLi_QUERYARGUMENTS, action: BLOCK }
clientIp: <operator>, country: AR, user-agent: curl/8.7.1
```

The request was allowed, the WAF recorded that it *would* have blocked it, and
`clientIp` is the real client rather than the ALB. That last part is not the
`numTrustedHops` work paying off — the WAF sits in front of Envoy and reads the
address AWS observed directly.

Worth keeping in mind: the WebACL attaches to the load balancer and is
indifferent to what sits behind it. Whatever else the migration disturbs, the
WAF tier is not part of it.

### Open follow-ups

- **`kube_state_metrics` and `node_exporter` carry dead Bitnami pins.** Largely
  moot now: they are gated off, and kube-prometheus-stack — the argument for
  deleting rather than repointing them — is itself gone.
- **A readiness gate for the LBC webhook race** would codify in the config what
  is currently an ordering convention — apply `helm_release.alb_ingress` on its
  own, wait for its pods, then apply the rest. That order prevents the failure
  (verified Day 8), so this is now about not having to remember it rather than
  about the failure still being open.

---

## Uncommitted by design

- `network/terraform.tfvars` — `vpc_enable_nat_gateway`, flipped to `true` for
  a spin and back to `false` on teardown. The committed default stays `false`.
- `k8s-components/allowlist.local.auto.tfvars` — gitignored. Required unless
  `public_gateway.open_to_internet` is true, which it now is.
- `k8s-workloads/allowlist.local.auto.tfvars` — gitignored, and **required**
  while `echo_server.restrict_public_access` is true. This is the one that
  actually keeps the public hostname closed now that the perimeter is open.
- `shared/us-east-1/tools-atlantis-ecs/main.tf` — removal of a hardcoded
  personal IP from an ALB security-group rule, on an undeployed layer, so never
  planned or applied. The same IP remains in published history (commit
  `e7f6bfb8`, PR #880).
