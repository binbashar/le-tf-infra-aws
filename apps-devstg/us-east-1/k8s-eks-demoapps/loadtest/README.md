# echo-server data-plane benchmark (k6)

Side-by-side micro-benchmark of the three echo-server endpoints in the
`bb-apps-devstg-eks-demoapps` cluster. All three hosts terminate TLS at
different data planes and forward to the **same** `jmalloc/echo-server`
backend, so this measures the *relative* latency / error-rate cost of each
data plane. The backend's CPU limit and replica count are deliberately
varied between scenarios (see `test-results.md`) — when the backend is
small it caps absolute RPS for everyone equally (relative comparison still
valid); when it's lifted, the data planes' own latency becomes the
dominant signal.

| Host | Data plane |
|---|---|
| `echo-server.aws.binbash.com.ar`    | nginx-ingress (`Ingress`, private NLB) |
| `echo-server-eg.aws.binbash.com.ar` | envoy-gateway via `private-gw-eg` (`HTTPRoute`) |

A third host, `echo-server-kg.aws.binbash.com.ar` (kgateway via `private-gw`),
was measured alongside these until kgateway was removed in favour of Envoy
Gateway. `test-results.md` is the record of those three-way runs and still
reports it; the script and this guide cover the two remaining paths.

## Files
- `echo-server-k6.js` — the k6 script (canonical source; also runnable locally with `k6 run echo-server-k6.js` if you've added `/etc/hosts` overrides).
- `k6-job.yaml`        — `Namespace` + `Job` running `grafana/k6:0.50.0`, pinned to the apps node group (`stack=standard`).
- `kustomization.yaml` — generates the `ConfigMap` (script) from `echo-server-k6.js` so the `.js` stays the single source of truth.

## Load profile

`echo-server-k6.js` is the **live** script — its profile changes per
benchmark scenario. The full catalog (each scenario's profile, backend
config, thresholds, results, and read) lives in
[`test-results.md`](./test-results.md). At rest the file holds whichever
scenario was run last; re-create any prior scenario from the diff recorded
in its `test-results.md` entry.

Profiles used so far: closed-loop `ramping-vus` ramps (2 min), open-loop
`constant-arrival-rate` step tests, and a 15-min rate-controlled soak.
All run one scenario per host in parallel and tag every metric
with `{host:nginx|envoy}`.

### Thresholds — gates vs. visibility
Two kinds of thresholds appear in the script:

| metric | typical bound | purpose |
|---|---|---|
| `http_req_failed{host:*}` | `rate < 0.01` (relaxed to `< 0.05` for knee-finding step tests) | **gate** — TLS / TCP / 5xx / client-side-timeout rate |
| `checks{host:*}` | `rate > 0.99` | **gate** — backend returned HTTP 200 |
| `http_req_duration{host:*}` (and `{host:*,rate:*}` in step tests) | `p(99) < 10 s` | **visibility only** — k6 omits tagged sub-metrics from the summary unless they carry a threshold; 10 s is the request timeout so it never actually gates |
| `dropped_iterations{scenario:*}` | `count < ∞` | **visibility only** — surfaces unmet demand per step in arrival-rate runs |

This is a benchmark, not an SLO gate — read the per-host
`http_req_duration{host:X}` blocks in the summary for the latency numbers.
A *failing* threshold means something actually broke (a TLS handshake, an
HTTPRoute, the backend) — k6 exits non-zero and the Job's
`condition=complete` flips to `Failed`.

### Generator sizing gotcha
On a fast backend a `constant-vus` profile can fire tens of thousands of
req/s, and k6 keeps every metric sample in RAM for end-of-test percentiles
— a long run will `OOMKill` the generator pod. For sustained / soak runs
use `constant-arrival-rate` (predictable load regardless of backend speed),
set `discardResponseBodies: true`, and give the k6 container enough memory
(currently `limits.memory: 2Gi` in `k6-job.yaml`).

## Pre-reqs
The k6 Job runs in-cluster, so the only thing the user's machine needs is
`kubectl` pointed at the cluster:

```bash
cd apps-devstg/us-east-1/k8s-eks-demoapps/cluster
leverage terraform refresh-credentials      # if creds are stale

export AWS_CONFIG_FILE=~/.aws/bb/config
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/bb/credentials
export KUBECONFIG=~/.kube/bb/apps-devstg
aws eks update-kubeconfig --region us-east-1 \
  --name bb-apps-devstg-eks-demoapps \
  --profile bb-apps-devstg-devops
```

VPN access to the cluster's private endpoint is required (same as for any
other `kubectl` work against this cluster). The k6 pod itself reaches
echo-server via the cluster's VPC resolver, so no laptop DNS gymnastics.

## Run

```bash
cd apps-devstg/us-east-1/k8s-eks-demoapps/loadtest

kubectl apply -k .

kubectl -n loadtest wait --for=condition=complete --timeout=5m job/echo-server-k6

kubectl -n loadtest logs -f job/echo-server-k6
```

The k6 summary at the end of the logs is tag-grouped — look for the
`{host:nginx}` and `{host:envoy}` blocks in the threshold
list and in the trend stats.

## Re-run
The Job spec is immutable; to re-run with the same or an updated script:

```bash
kubectl delete -k .            # tears down Namespace + Job + generated CM
kubectl apply  -k .
```

The Job auto-cleans its pod 10 min after completion (`ttlSecondsAfterFinished:
600`). The Namespace stays until you `kubectl delete -k .` (or
`kubectl delete ns loadtest`) so previous logs remain browsable.

## Interpreting results

- **Mind the backend cap.** When `echo-server` is small (e.g. 50–100 m CPU,
  1 replica) the backend saturates well below what the data planes can
  deliver — absolute RPS / latency say more about the backend than the
  proxies. The *relative* comparison between `{host:nginx}` and
  `{host:envoy}` is still valid (same backend ceiling for both). With the
  backend lifted (500 m × 3 replicas), the data planes' own cost dominates —
  that's where per-host latency genuinely diverges.
- **The interesting comparison is relative.** Both scenarios hit the
  same backend through identical-shape load, so any difference in
  `http_req_duration` / `http_req_waiting` between the hosts is the data
  plane: TLS termination cost, HTTP/2 negotiation with the LB, connection
  pooling, internal NLB hop count, etc.
- **`http_req_failed{host:envoy}` should be `0.00%`.**
  `{host:nginx}` has shown a small, repeatable client-side-timeout tail
  (~0.04–0.11 %, load-independent). Both paths sit behind AWS-LBC-managed
  NLBs — the difference is target-type: nginx-private uses **`instance`**
  (NLB → worker-node NodePort, `externalTrafficPolicy: Local`) while envoy
  uses **`ip`** (NLB → Envoy pod ENI directly). The NodePort layer and
  target-health/registration timing of `instance` mode is the most likely
  source of nginx's tail (not confirmed). Anything materially above that, or
  any non-zero rate on the two `ip`-target paths, is a real failure mode
  (TLS handshake, cert expiry, gateway programming, backend OOM).
- Latency is dominated by the **client → NLB → data-plane → backend** path
  inside the VPC, ~sub-ms RTT, so with the backend out of the way absolute
  numbers are low single-digit-ms at the median.
- See [`test-results.md`](./test-results.md) for the full scenario catalog,
  the cross-scenario summary, and the running read of "which data plane is
  fastest / most reliable".

## Cleanup

```bash
kubectl delete -k .
# or, equivalently for a full wipe (including the namespace):
kubectl delete ns loadtest
```
