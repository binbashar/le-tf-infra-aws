# EKS DemoApps — Platform Notes

Branch: `feature/eks-demoapps-kgateway-private-gateway`
Cluster: `bb-apps-devstg-eks-demoapps` (us-east-1)

Why the cluster is built the way it is, and what bites when standing it up or
taking it down. Routine mechanics — layer ordering, apply counts, credential
refreshes — live in `README.md`; the ingress topology is drawn out in
`k8s-components/README.md`.

**What this cluster is for.** It models a production topology being migrated
off nginx-ingress, so that the migration can be rehearsed here rather than
there. That topology is:

| | modelled setup | here |
|---|---|---|
| public | ALB + ACM + WAF → nginx pods → app | ALB + ACM (+ WAF, held ready) → **Envoy** → app |
| private | NLB → nginx pods → app | NLB → **Envoy** → app |
| DNS | external-dns private + public, on Ingress | same, on Ingress + HTTPRoute |
| certs | cert-manager per Ingress | one wildcard per Gateway listener |

The perimeter is meant to stay recognisable; the data plane is what changes.
**Reintroducing nginx here is never an option** — replacing it is the point.

**Current state (2026-09-01).** Torn down, after a full re-spin that validated
the `terraform-aws-eks` **v21.25.0** bump (see "The v20 → v21 module bump"
below). Everything below the VPC is gone; `vpc-0c2dd28735d0250c3` is kept for a
fast re-spin, with the `network` layer applied and
`vpc_enable_nat_gateway = false`. Note that resting state: `network` is *applied
without a NAT*, never destroyed — see "Tearing down". When up it is EKS 1.34 on
AL2023 with spot nodes and both public and private paths on Envoy Gateway.

**No WAF is deployed.** It was built, attached, verified and taken back down the
same day; the code is all in place behind the ` --` exclusion. See "AWS WAF"
below for what re-attaching costs.

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
| 8 | 2026-08-10 | Re-spun from scratch, then torn down again. **AWS WAF attached to the ALB, verified, then detached and destroyed** — backlog item 4 closed. **Managed add-ons caught up to 1.34**, `vpc-cni` stepwise. **nginx-ingress removed from the code.** |

---
| 9 | 2026-08-28 | Re-spun to verify the PR #1136 review items. **Component HTTPRoutes moved onto the charts' native keys.** ACME endpoint made switchable; Secret preservation proven. Torn down again, both DNS zones clean. |
| 10 | 2026-09-01 | **`terraform-aws-eks` v20.37.2 → v21.25.0**, `aws-auth` → access entries, AWS provider → 6.x. Three latent no-op inputs fixed. Re-spun end to end to validate it — both routes 200, zero drift on all six layers — then torn down. Three defects found that no plan could catch. |

---

## Architecture decisions

### Envoy Gateway is the data plane; nginx and kgateway are gone

Three implementations ran in parallel before choosing (`loadtest/test-results.md`
has the numbers). The decision hinged on a benchmark result that reversed the
prior reading: **scenario S6 — the controlled test, both data planes on
identical `instance`-target plumbing — showed Envoy at zero failures over 450k
requests against nginx's 425 (0.09%).** The long-standing "nginx is faster"
ordering had been an artifact of comparing different NLB target types.

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
had been at `enabled = false` since, which is what made the removal cheap:
nothing nginx-shaped was in state, so deleting it is a pure code change and
`tofu plan` returning `No changes` *is* the verification.

**traefik stays**, by decision — it was never used here either, but it is not
what this cluster is about. Removing nginx from beside it did require untangling
them: the two counts encoded a mutual exclusion, which collapses to plain
`traefik.enabled` now that there is nothing to be exclusive with.
`var.ingress.apps_ingress` and `local.load_balancer_attributes` survive for the
same reason — it is `traefik_apps`, not the Envoy ALB, that consumes them.

What deliberately did **not** change: every historical mention of nginx in this
file and in the layer's code and READMEs. The `whitelist-source-range`
annotation this cluster set out to translate, the 308 redirect Gateway API
rejects, the benchmark that settled it — deleting the code is not a reason to
delete the reasoning.

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

### Component routes come from the charts, not from terraform

Every component that publishes a hostname does it through its own chart's
Gateway API key — `server.httproute` (argo-cd), `dashboard.httproute`
(argo-rollouts), `gateway.route` (gatus), `dashboard.httpRoute` (goldilocks),
`<component>.route.main` (kube-prometheus-stack). None of it needed a version
bump; the support was already there at the pinned versions.

They were hand-written `kubernetes_manifest` HTTPRoutes until 2026-08-28. Moving
them onto the charts removed seven resources and put each route on a path its
chart supports and tests.

**The migration needs no state surgery**, which was the expected cost. Helm
refuses to adopt an object it does not own, so the assumption was `state rm`
plus a manual delete. It resolves itself: each hand-written route declared
`depends_on` its own `helm_release`, so Terraform destroys the dependent *before*
modifying the dependency, and Helm creates the replacement — same name, same
hostname, same backend — later in the same apply. There is a sub-second window
with no route, which would matter on a busy hostname.

Two exceptions, both deliberate:

- **`uptime-kuma` 4.1.0 has no Gateway API support at all** — its values expose
  `ingress` and nothing else — so `uptime_kuma_route_eg` stays a
  `kubernetes_manifest`, next to its release.
- **The platform's own routes stay in terraform**: both `GatewayClass`es, both
  `Gateway`s, the `EnvoyProxy`s, the `ClientTrafficPolicy`, the healthz filter
  and route, the two HTTP->HTTPS redirects. No chart owns them.

So the two-stage apply does **not** go away — 15 `kubernetes_manifest` resources
remain and they all validate against the live API at plan time. The win is less
code on a supported path, not one less apply stage.

One behavioural difference to know: the Argo CD chart points its `backendRef` at
the Service's `https` port (443) where the hand-written route used `http` (80).
Equivalent here — both ports target 8080, `server.insecure` makes that port
plain HTTP, and neither carries an `appProtocol` — so Envoy stays cleartext
upstream either way.

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
the policy to live in k8s-workloads next to the route. That constraint points at
the right answer anyway: the annotation being replaced carries a value that
belongs to the application. So there are **two lists on purpose** -
`envoy_gateway_public_allowed_cidrs` (who may reach the cluster, on the load
balancer) and `echo_server_public_allowed_cidrs` (who may reach this app, inside
Envoy). They hold the same value only while there is one operator. Both live in
gitignored `allowlist.local.auto.tfvars` files, top-level rather than fields of
`envoy_gateway` because tfvars cannot merge into an object variable.

`defaultAction: Deny` rather than relying on the absence of a match: a rule set
that only lists allows, with a permissive default, fails open on a typo.

With that in place the ALB was opened to `0.0.0.0/0`, matching the modelled
setup. The perimeter allowlist had always been a stand-in, and keeping it closed
would be a second place to forget as well as a mask — a route whose policy is
broken looks fine from inside the allowlist. `open_to_internet` exists so that
"open" is written down: the same state was reachable by leaving the CIDR list
empty, which is indistinguishable from having forgotten to fill it in.
**Empty means mistake; the flag means decision.** While it is false, a
`precondition` fails the plan on an empty list, since the LBC would otherwise
default the security group to `0.0.0.0/0` anyway.

Verified with the perimeter open, which is the configuration where a broken
policy is actually exposed: allowed CIDR → 200, `192.0.2.0/24` → 403
`RBAC: access denied`, restored → 200.

**The public HTTPS listener uses a label Selector, not `from: All`.** A namespace
must carry `gateway.binbash.com.ar/public-exposure=allowed`, so writing an
HTTPRoute is not by itself enough to reach the internet. EG resolves
`EnvoyProxy` through `GatewayClass.parametersRef` rather than per Gateway, so the
public data plane needed its own GatewayClass; the naming is asymmetric as a
result, since `gatewayClassName` is immutable and renaming the private class
would have recreated its Gateway and NLB.

### Certificates: one wildcard per listener, and how not to re-issue

Each Gateway listener binds one wildcard, which is what makes the flat hostname
scheme worth having. Issuance is cert-manager against Let's Encrypt over DNS01,
through the shared ClusterIssuer in `networking-cluster-issuer.tf`.

**Let's Encrypt allows 5 duplicate certificates per week** for an identical set
of identifiers, and a fresh ACME account does not reset it. This layer asks for
two fixed sets — `aws.binbash.com.ar` + `*.aws.binbash.com.ar`, and
`*.binbash.com.ar` — so a week with six rebuilds stops issuing, and the second
set is the corporate wildcard, whose blast radius is outside this layer.

**The cheap answer is not to re-issue at all.** cert-manager sets no
`ownerReference` on the TLS Secret (the default
`--enable-certificate-owner-ref=false`), so the Secret outlives the `Certificate`
that produced it. Verified 2026-08-28: destroying and re-creating
`helm_release.private_gw_eg_tls` left the Secret in place and the new
`Certificate` went `Ready` reusing it — same `notBefore`, same serial, no
`Order`, no `Challenge`, `Events: <none>`. It never contacted ACME.

So carry the Secrets across a teardown:

```bash
# before the teardown
kubectl get secret private-gw-eg-wildcard-tls public-gw-eg-wildcard-tls \
  -n envoy-gateway-system -o yaml > wildcards.yaml

# after the re-spin, once the namespace exists and before cert-manager
# reconciles the new Certificates
kubectl apply -n envoy-gateway-system -f wildcards.yaml
```

Strip `resourceVersion`, `uid` and `creationTimestamp` first. A certificate is
good for 90 days, so a Secret is worth preserving for about a month of
rehearsals before renewal makes it moot.

**The fallback is `certmanager.acme_staging = true`**, which points both
ClusterIssuers at the staging directory — far looser limits, untrusted
certificates by design. Use it when the Secrets are gone, or when the issuance
path itself is what is being rehearsed. The account key is suffixed `-staging`
so one Secret does not end up holding an identity registered on two servers;
the chart-based issuer derives its key name from the release name and cannot do
that, but nothing requests certificates through it today.

The private zone has no public NS delegation, so `_acme-challenge` queries climb
to the public zone where cert-manager can write. That fall-through is what lets
a private-only zone pass ACME DNS01.

### AWS WAF sits on the ALB, and the ALB was the point

AWS WAF attaches to CloudFront, ALB, API Gateway, AppSync, Cognito, App Runner
and Verified Access — **not to NLB**, which used to front both Gateways. That
looked like a choice between CloudFront, an ALB, or an in-Envoy equivalent, and
the framing was wrong: the setup being modelled *already runs ALB + WAF*, so the
ALB was never the obstacle to route around — it was the target. CloudFront and
Cloudflare were ruled out, `ext_authz` rejected because body inspection needs
buffering and without bodies a WAF misses half of what it is for, and
Coraza-on-Wasm kept only as a side experiment.

Built, attached, verified and taken back down on 2026-08-10. What it took:

- **`apps-devstg/us-east-1/security-firewall --` renamed out of its ` --`
  exclusion** and applied — three resources: the WebACL, its logging
  configuration and the `aws-waf-logs-wafv2-apps` log group. `infracost.yml`
  needs the path updated to match. **It went back behind the marker afterwards**:
  the marker tracks the deployed set, and this is a capability held ready rather
  than one this cluster runs. The backend key does not contain the directory
  name, so the rename migrates no state either way.
- **The association is made by the Load Balancer Controller**, from
  `alb.ingress.kubernetes.io/wafv2-acl-arn` on `kubernetes_ingress_v1.envoy_apps`,
  never by a `wafv2_web_acl_association`. Nothing that plans before the ALB
  exists can know its ARN, and the ARN changes on every re-spin — and this is
  also how the modelled setup attaches its WAF. **It is one-way**; see the
  gotcha about detaching before trusting `waf_enabled = false`.
- **The ARN crosses layers by remote state**, behind
  `envoy_gateway.public_gateway.waf_enabled`, with the data source itself
  `count`ed so `k8s-components` still plans standalone with the WAF off.
- The LBC's IAM role already held `wafv2:AssociateWebACL` — verified, not
  assumed.

**Two managed rule groups were dropped rather than counted.** Bot Control,
because its `CategoryHttpLibrary` signal targets exactly the non-browser clients
every check against this cluster uses, and ATP, because it was aimed at a login
path nothing here serves. Each bills about $10/month, so both were paying to
protect nothing while threatening to break the tests. The remaining six run at
priorities 0-5, **all in COUNT** — a rule is promoted to `block` only after its
counted requests show no legitimate traffic caught.

Re-attaching is: rename the layer, restore its `infracost.yml` path, apply it,
set `waf_enabled = true`.

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

### The v20 → v21 module bump, and three things a plan cannot catch

`terraform-aws-eks` went from `v20.37.2` to **`v21.25.0`** on 2026-09-01, which
also forced the AWS provider from `~> 5.74` to `~> 6.59` (v21's floor). The
timing was deliberate: the stack was torn down, so the bump landed as a
greenfield create — `Plan: 49 to add, 0 to change, 0 to destroy` — with no state
moves and no node-group replacements.

The mechanical part was the easy part: the `cluster_*` prefix is stripped from
most inputs, `eks_managed_node_group_defaults` is gone (as is every other
`*_defaults` variable — the module iterates `eks_managed_node_groups` directly
with no merge step, so `local.node_group_defaults` + `merge()` restores the
single-source-of-truth property by hand), and the `aws-auth` submodule is gone.

**The upgrade guide's scariest line is wrong for this layer.** It warns that the
IRSA OIDC issuer URL moves to the dual-stack `oidc-eks` endpoint. It does not:
v21.25.0 still sets `aws_iam_openid_connect_provider.url` from the cluster's own
issuer, and the `oidc-eks` form is only a *new output*
(`cluster_dualstack_oidc_issuer_url`). The issuer came out as
`oidc.eks.us-east-1.amazonaws.com` as always, so the 12 IRSA roles in
`identities` and the cross-account provider in `shared` were never at risk.

What the guide does *not* warn about is the three defects below. All three were
found by applying — every one of them plans clean.

#### 1. A fresh v21 cluster has no CNI, so no node ever joins

v21 hardcodes `bootstrap_self_managed_addons = false` and no longer exposes it as
a variable. v20 defaulted it to `null`, so the argument was omitted and the AWS
API default of `true` applied: **EKS installed self-managed kube-proxy, CoreDNS
and VPC CNI when the cluster came up.** That is what let nodes join on Days 1–9,
and why the `addons` layer — two layers later, after `identities` — could behave
as an upgrade rather than a first install. Its
`resolve_conflicts_on_create = "OVERWRITE"` exists precisely to convert those
self-managed daemonsets into managed add-ons.

Under v21 that ordering deadlocks. Observed: `aws eks list-addons` returned `[]`,
three instances came up and sat there, and both node groups blocked at
`Still creating...` for 16 minutes, because a node cannot reach `Ready` without a
CNI. They would have burned their full create timeout and failed.

The CNI is now installed from the `cluster` layer via `local.bootstrap_addons`
with **`before_compute = true`**, which the module routes to
`aws_eks_addon.before_compute` — created ahead of the node groups. It carries no
`service_account_role_arn`, because the IRSA role for it lives in `identities`,
which cannot exist yet on a fresh cluster; the CNI runs on the node instance
role, which already carries `AmazonEKS_CNI_Policy` via
`iam_role_attach_cni_policy`. `most_recent = false` is set explicitly, because
that default flipped to `true` in v21 and would otherwise resolve the newest
published CNI on every apply instead of the default for the cluster's Kubernetes
version — unwanted drift on the one add-on that has needed stepwise upgrades
here before (see "The add-ons were left three minors behind").

**`vpc-cni` is correspondingly absent from the `addons` layer.** Declaring it in
both places fails with `ResourceInUseException`. The consequence, noted in both
files: the `eks_addons_vpc_cni` IRSA role in `identities` is now unused.

#### 2. Access entries reject SSO role ARNs with the IAM path stripped

The `aws-auth` ConfigMap wanted IAM Identity Center role ARNs with the
`/aws-reserved/sso.amazonaws.com/` path removed, and the old `map_roles`
followed that convention. **It does not carry over.** Access entries validate
that the principal exists, so the path-less form is rejected:

```text
InvalidParameterException: The specified principalArn is invalid: invalid principal.
```

Use the ARN verbatim, path included. EKS stores it as given — the service-linked
`AWSServiceRoleForAmazonEKS` entry it creates for itself is path-ful too — so
there is no normalisation diff to chase.

Two more things about that migration. `enable_cluster_creator_admin_permissions`
is now **`false`** on purpose: the module merges the flag's bootstrap entry into
`access_entries` by *map key*, not by principal, so with the SSO DevOps role
listed explicitly the flag would produce two `aws_eks_access_entry` resources for
one principal and fail with `ResourceInUseException`. And EKS access policies are
**not** IAM policies — they live under `arn:aws:eks::aws:cluster-access-policy/`,
and the IAM form fails with `The policyArn parameter format is not valid`.

Fixed on the way: the pinned SSO role ARN had gone stale. The permission-set
suffix is generated by Identity Center and changes when the permission set is
recreated, so that aws-auth entry had been granting nothing. It is resolved via
`data.aws_iam_roles` now rather than pinned.

#### 3. IMDS hop limit 1 breaks the Load Balancer Controller

v21 drops the node groups' IMDS `http_put_response_hop_limit` from 2 to **1**,
which puts instance metadata out of reach of anything inside a pod. Verified
directly: a throwaway pod cannot get an IMDS token, while IRSA keeps working.

That is a *hardening* win, and everything here authenticates via IRSA — but the
AWS Load Balancer Controller discovers its **VPC ID** from IMDS, which IRSA has
nothing to do with. Both replicas crash-looped and the Helm release timed out
with `context deadline exceeded`:

```text
unable to initialize AWS cloud: failed to get VPC ID: failed to fetch VPC ID
from instance metadata
```

The fix is to pass `vpcId` and `region` to the chart explicitly, which is what
AWS documents, and which is better than raising the hop limit back to 2: it
removes the IMDS dependency instead of reopening metadata to every pod on the
node. The VPC ID reaches `k8s-components` as a new `vpc_id` output on the
`cluster` layer, rather than a sixth `terraform_remote_state` block.

**Note the shape of this failure**, because it generalises: the symptom named
neither IMDS, nor hop limits, nor the module bump. Anything else in a cluster
that reads instance metadata from a pod will fail the same opaque way after this
upgrade.

#### Three inputs that were silently doing nothing

v20 typed the node-group defaults as `any`, which discarded unknown keys without
complaint. v21's typed object turns them into hard errors, which surfaced two of
these; the third came out of reading the plan.

- **`k8s_labels = local.tags`** was never a real input — the submodule's key is
  `labels`. Those tags never landed as Kubernetes labels. The per-group `labels`
  are the ones that always worked.
- **`disk_size = 50`** had been a no-op since 2023. The module sets
  `disk_size = use_custom_launch_template ? null : disk_size`, and
  `use_custom_launch_template` defaults to `true`, so the size has to come from
  the launch template. Every node on Days 1–9 ran on the AL2023 AMI default of
  20 GiB. Now delivered for real via `block_device_mappings` (50 GiB gp3,
  encrypted). Identical logic in v20.37.2 and v21.25.0 — a latent bug, not a v21
  regression.
- **`data.terraform_remote_state.cluster-identities`** in `cluster/config.tf` was
  dead code declaring a false *reverse* dependency on `identities`, which
  actually depends on `cluster`. Removed, along with `data.aws_eks_cluster` and
  the whole `kubernetes` provider — which existed only to feed the aws-auth
  ConfigMap. **The `cluster` layer no longer touches the Kubernetes API at all,
  so it no longer needs VPN access.**

#### Also worth knowing

Two other v21 defaults are left alone but written down in `cluster/variables.tf`:
`use_latest_ami_release_version` is now `true`, so an apply following an AWS AMI
release will roll the nodes; and `enable_monitoring` is now `false`, which is
what this cluster wants. `control_plane_egress_mode` — the one-way switch for
routing control-plane egress through your own VPC — becomes available in v21 but
is deliberately not touched here.

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

### Latent bugs surfaced by turning components on, and the Day 6 trim

None were caused by the HTTPRoute conversion; they were sitting in config that
had never been executed. **Bitnami's 2025 catalog purge** removed
`metrics-server` 5.8.4 from the public repo (moved to the kubernetes-sigs chart;
`extraArgs` map → `args` list), and `kube_state_metrics` and `node_exporter`
still carry the same dead pins. **Gatus's config could never have worked** -
`config.services` was renamed to `config.endpoints`. **Alertmanager was
hardcoded `enabled: true`** while its variable was false, so it would have
rendered with an empty `slack_api_url`, which it refuses to start on.
**argo-rollouts carried `backend-protocol: HTTPS`**, copy-pasted from Argo CD.

Day 6 then trimmed the component set to echo-server: kube-prometheus-stack
including Grafana, goldilocks, VPA, metrics-server, uptime-kuma, gatus, Argo CD
and Argo Rollouts, 19 resources in one clean pass with no orphaned PVCs.
`argocd.rollouts.enabled` is evaluated **independently** of `argocd.enabled`, so
both flags have to move together or Rollouts installs with no Argo CD beside it.

Deliberately still off: **Alertmanager**, which needs
`/notifications/alertmanager` in the shared account — enabling it fails the plan
at the data source, which is also why its route is the one piece of the chart
migration never exercised live — and **argocd-image-updater**, since a chart
that cannot be deployed cannot be verified.

---

## Spinning up

Order is `network → cluster → identities → addons → k8s-components ->
k8s-workloads`, with `vpc_enable_nat_gateway = true` in `network` first -
without a NAT the nodes never join. `README.md` has the per-layer detail; what
follows is only what goes wrong.

**`k8s-components` needs a two-stage apply on a fresh cluster.**
`kubernetes_manifest` validates against the live API at *plan* time, so
`EnvoyProxy` manifests fail before their CRDs exist. Stage 1 targets the two CRD
manifests plus the EG controller; the full plan is clean afterwards. Note a
standalone `tofu plan` can report clean while the *apply's own* plan phase
fails — a green plan is not proof.

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

**The kubeconfig goes stale on every re-spin.** `~/.kube/bb/apps-devstg` and
`~/.kube/bb/config` pin the previous cluster's API endpoint, so `kubectl` fails
with `no such host` against a perfectly healthy cluster. Refresh both with
`aws eks update-kubeconfig --name bb-apps-devstg-eks-demoapps --region us-east-1
--profile bb-apps-devstg-devops --kubeconfig <file>`.

**Both `allowlist.local.auto.tfvars` files are required and gitignored.**
Recreate them from the `.example` next to each if the tree was cleaned; the
k8s-workloads one is what keeps the public hostname closed now that the
perimeter is open.

---

## Tearing down

`vpc_enable_nat_gateway = false` is the cost switch — the NAT Gateway is the
standing charge, and the VPC is kept across teardowns for a fast re-spin. The
committed default is `false`, so flipping it to `true` is a local working change
and not something to commit.

**`network` is never destroyed.** Its teardown is that flag plus an `apply`,
which removes three resources — NAT Gateway, its EIP, the default route — and
leaves the VPC, subnets, route tables and Route53 associations standing. That
applied-without-a-NAT state *is* the resting state. `tofu destroy` there takes
everything but the VPC (which survives only because AWS answers
`DependencyViolation` while the peerings still reference it), and the repairing
`apply` brings the route tables back with **new IDs** — at which point the
peering routes inside them are gone, because they are not owned here.
`shared/us-east-1/base-network` writes them across accounts from this layer's
outputs, so the damage surfaces there as two missing
`module.vpc_peering_apps_devstg_to_shared[...].aws_route.peer_routes`, and
nothing reaches the cluster over the VPN until that layer is applied again.
Learned the hard way on 2026-08-28.

**Delete the DNS-producing objects first and let external-dns clear the records
while it is still alive**, for *both* zones. The rule is about the sync window,
not about any particular object: after deleting the last thing that owns a
record, wait a full external-dns cycle (3 minutes) and check both zones before
moving on to the layer that removes external-dns. Which objects those are:

- **public** — `kubernetes_ingress_v1.envoy_apps`, since the ALB's Ingress is
  what publishes the record. The public HTTPRoutes are hidden from external-dns
  and produce nothing.
- **private** — the component helm releases that carry a hostname, plus
  `k8s-workloads` for echo-server's.

Then the rest, in reverse dependency order: `k8s-components` → `addons` ->
`identities` → `cluster` → `network`.

**Skipping the DNS step is fatal, not untidy** — see the next section. The
2026-08-28 teardown followed it and both zones came out clean: three public
records cleared on the Ingress destroy, eighteen private ones in a single batch
after the component releases went, leaving only the known-inert `a-echo-server`
TXT.

**The 2026-09-01 teardown got the public half right and the private half wrong**,
which is worth recording because the failure is asymmetric and easy to repeat.
`kubernetes_ingress_v1.envoy_apps` was destroyed on its own and the public record
was *polled until it disappeared* before anything else moved — clean. But
`k8s-workloads` was then chained straight into the `k8s-components` destroy
without the same wait-and-check on the private zone, so external-dns-private went
down inside its own sync window and left three records behind:
`echo-server.aws.binbash.com.ar` A and TXT, and `cname-echo-server.aws...` TXT.

Note that the rule above already says to do this — "wait a full external-dns
cycle (3 minutes) and check both zones before moving on to the layer that removes
external-dns". The trap is that the public step *feels* like the DNS step,
because it is the one that gets its own targeted destroy. It is only half of it.
The private records have no dedicated destroy of their own, so the pause has to
be deliberate.

Cleaned up with a single `change-resource-record-sets` DELETE batch. That
`cname-` TXT in particular cannot be left: unlike the inert `a-echo-server` one
in the public zone, a stale `cname-<host>` registry record collides on the next
spin and crash-loops the external-dns controller.

**Destroy ordering is a drain gate, not `depends_on`.**

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

**The same validation blocks destroys.** Once CRDs are gone, `tofu destroy`
fails on manifests no longer in state. Work around with `-target`, or set the
layer's `enabled` toggles to false first.

**A WebACL cannot be deleted while it is associated.** The association belongs
to the ALB, which belongs to the Ingress in `k8s-components` — so that layer
(or at least `kubernetes_ingress_v1.envoy_apps`) has to go before
`security-firewall`. Same shape as the drain gate: the thing holding the
reference is not the thing that owns it in Terraform.

**A leftover CNI ENI can hold the node security group for ten minutes.** On the
2026-08-28 teardown `aws_security_group.node` sat in `Still destroying...` while
an `available` (detached) ENI named `aws-K8S-i-<instance-id>` still referenced
it. Find it with
`aws ec2 describe-network-interfaces --filters Name=group-id,Values=<sg>` and
delete it; the retry then succeeds. Same family as the drain gate — AWS
garbage-collects asynchronously and Terraform does not wait.

### Orphaned registry records are a landmine, not litter

The 2026-08-28 re-spin came up with `externaldns-private` in
`CrashLoopBackOff`, ten restarts, on a cluster that was otherwise healthy:

```
Desired change: CREATE cname-echo-server.aws.binbash.com.ar TXT
Desired change: CREATE echo-server.aws.binbash.com.ar A
Desired change: CREATE echo-server.aws.binbash.com.ar TXT
Failure in zone aws.binbash.com.ar.: InvalidChangeBatch: [Tried to create
  resource record set [name='cname-echo-server.aws.binbash.com.ar.',
  type='TXT'] but it already exists]
fatal: failed to submit all changes for the following zones
```

The private zone held **only** `cname-echo-server.aws.binbash.com.ar` TXT —
owner `devstg-eks-demo-prv`, resource `httproute/echo-server/echo-server-eg`,
with no A and no plain TXT beside it. Exactly the residue the Day 8 teardown
left by destroying `k8s-workloads` and `k8s-components` back to back.

Three things to keep:

- **external-dns keys its registry on the plain `<host>` TXT.** The `cname-`
  prefixed record alone does not mark the hostname as already published, so it
  plans a CREATE for all three records. Route53 rejects a batch in which any
  one change conflicts, so the two records that *were* missing never get
  written either.
- **v0.14.0 treats a rejected batch as `fatal`.** The process exits, the pod
  crashloops, and every other hostname in that zone stops being reconciled.
  `gatus` and `goldilocks` only had records because they were published before
  echo-server's route existed.
- **Whether leftovers are harmless comes down to name collision, not
  ownership.** `a-echo-server.binbash.com.ar` in the public zone is inert
  because external-dns publishes `cname-echo-server` + `echo-server` there and
  never needs that name. The private `cname-echo-server` was fatal because it
  is precisely the name the controller had to create. Same owner ID in both
  cases — the owner ID is what makes a record *adoptable* in principle, and it
  buys nothing when the API call fails before adoption is ever considered.

Recovery is one `DELETE` of the orphan (kept in the shared account, so
`--profile bb-shared-devops`), then let the controller retry — deleting the
crashlooping pod skips the backoff:

```bash
aws route53 change-resource-record-sets --hosted-zone-id <PRIVATE_ZONE_ID> \
  --profile bb-shared-devops --change-batch '{"Changes":[{"Action":"DELETE",
  "ResourceRecordSet":{"Name":"cname-echo-server.aws.binbash.com.ar.",
  "Type":"TXT","TTL":300,"ResourceRecords":[{"Value":"\"<the exact TXT value>\""}]}}]}'
kubectl delete pod -n externaldns -l app.kubernetes.io/instance=externaldns-private
```

It came back `1/1 Running`, created the full triple on the first reconcile, and
all four hostnames answered: `echo-server.aws` 200, `gatus.aws` 200,
`goldilocks.aws` 301 → `/namespaces` 200 (the app's own redirect), and
`echo-server.binbash.com.ar` 200 through the ALB.

---

---

## Recurring gotchas

**An empty map is not an empty map.** The kubernetes provider serialises `{}`
as `null`, which a CRD requiring an object rejects
(`must be of type object: "null"`). To say "no annotations", omit the key —
`merge()` a conditional fragment in rather than setting the field to `{}`.

**Prove an allowlist from a different source address, not by editing the list.**
A 200 only shows the request arrived, not that anything was discriminated — if
the policy were missing entirely the operator would still get 200. Two
independent traps make the naive check useless: **security groups are stateful**,
so an established keep-alive connection keeps working after a rule tightens
(always `curl --no-keepalive`), and **`WebFetch` egresses from the operator's own
machine**, so it is not a second vantage point at all.

The cheap second vantage point is **from inside the cluster**: a throwaway pod
egresses through the NAT Gateway, so its public address is the NAT EIP, which is
by construction not on any operator allowlist.

```
kubectl run probe --rm -i --restart=Never --image=curlimages/curl:8.11.1 \
  --command -- curl -s -m 25 -o /dev/null -w '%{http_code}\n' \
  https://echo-server.binbash.com.ar/
```

Verified 2026-08-10: `403` with the body `RBAC: access denied` from the pod
against `200` from the operator's machine. Same URL, same config, only the
source address differs. The body matters — `RBAC: access denied` is Envoy's RBAC
filter specifically, where the ALB would have refused the connection and a
routing miss would be 404.

It also proves something the config-editing version cannot: that
`numTrustedHops` extracts the origin address correctly. If Envoy were reading
the ALB as the client, both requests would present the *same* address and land
the same way. That they diverge is the proof.

Swapping the real CIDR for `192.0.2.0/24` (TEST-NET) is still the only way to
test a CIDR *boundary*, since the source address is not selectable here. But it
mutates config to test behaviour, and a failed apply mid-swap leaves the endpoint
either locked or open, so prefer the pod.

**A WAF in COUNT needs the same treatment, and the logs supply it.** Every
request returns 200 whether or not a rule matched, so response codes prove
nothing at all. Send a probe that *should* match — `?q=1' OR '1'='1` trips
`SQLi_QUERYARGUMENTS` — and read `aws-waf-logs-wafv2-apps`:
`nonTerminatingMatchingRules` carries the COUNT, and the rule group's
`terminatingRule` shows the action it would have taken in enforce mode. An
empty log is the real failure signal, because it means the WebACL is
associated but not in the request path.

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

**This cluster has no default StorageClass.** `gp2` exists but is not annotated
as default, and a classless PVC never binds and never errors — it sits Pending
until Helm times out. Every chart that provisions storage must name `gp2`
explicitly. (`gp2` still declares the in-tree provisioner, which 1.34 no longer
ships; the CSI migration shim rewrites it onto `ebs.csi.aws.com`.)

**`create_sg = false` is not `create = false`.** On
`terraform-aws-security-group`, the first suppresses the group and leaves its
rules in the graph, where each resolves `security_group_id` to null and fails
the plan with `Missing required argument`. Pass both. This sat latent in
`security-firewall` for as long as its demo ALB was switched on, and surfaced
the moment it was switched off.

**`leverage tofu` exit code is not trustworthy** — it has returned exit 0 on a
failed apply, including one where zero resources were created. Grep the output
for `Apply complete!` / `^Error:` instead, and strip ANSI first since it
colourises even when redirected.

**NLB targets read `unhealthy` for the first few minutes** after a gateway is
created, and an internet-facing NLB converges slower than an internal one. That
asymmetry looks exactly like a security-group fault. Re-check before
investigating. Separately, with `instance` + `Local`, nodes *not* running an
Envoy pod are `unhealthy` by design.

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

---

## Open follow-ups

- **`kube_state_metrics` and `node_exporter` carry dead Bitnami pins.** Largely
  moot: they are gated off, and kube-prometheus-stack — the argument for
  deleting rather than repointing them — is back but does not consume them.
- **A readiness gate for the LBC webhook race** would codify in the config what
  is currently an ordering convention. That order prevents the failure (verified
  Day 8 and again Day 9), so this is about not having to remember it rather than
  about the failure still being open.
- **Three locks still carry a single `h1:` hash.** `k8s-workloads` is
  regenerated for all four platforms; the same asymmetry remains in `cluster`
  (`kubernetes`, `local`, `tls`), `identities` (`tls`) and `k8s-components`
  (`kubernetes`, `time`). It only bites under `-lockfile=readonly`, which is how
  Atlantis runs: a platform with no `h1:` of its own fails instead of rewriting
  the lock. One command per layer:
  `tofu providers lock -platform=linux_amd64 -platform=linux_arm64
  -platform=darwin_amd64 -platform=darwin_arm64`.
- **Alertmanager's chart-rendered route has never run.** The workload stays off
  for want of a secret, so that one route of the seven is verified by templating
  only.

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
