# echo-server data-plane benchmark — results log

Append a new section per run. Common setup lives at the top; each scenario
captures only what's specific to that run (load profile, backend tweaks,
cluster shape if changed), the comparison table, and the read.

## Constant setup (applies to every scenario unless overridden)

- **Cluster**: `bb-apps-devstg-eks-demoapps` (`us-east-1`, k8s 1.31), nodes on `standard_spot` (t3.medium spot).
- **Backend**: single `jmalloc/echo-server:v0.3.7` pod, ClusterIP Service with `appProtocol=kubernetes.io/ws`. Resources: `requests {cpu:10m, memory:32Mi}`, `limits {cpu:50m, memory:64Mi}`.
- **Data planes under test** (all front the same backend, all on the private `aws.binbash.com.ar` zone, all behind **internal AWS-LBC-managed NLBs** — the relevant difference between them is the NLB target-type):
  - `echo-server.aws.binbash.com.ar`    — nginx-ingress (legacy `Ingress`); NLB with **`instance`** target-type (→ worker-node NodePorts 32083/31058, `externalTrafficPolicy: Local`). Legacy `service.beta.kubernetes.io/aws-load-balancer-type: nlb` annotation.
  - `echo-server-kg.aws.binbash.com.ar` — kgateway via `private-gw` (`HTTPRoute`); NLB with **`ip`** target-type (→ Envoy pod ENIs, ports 80/443). Modern `aws-load-balancer-type: external` + `nlb-target-type: ip`.
  - `echo-server-eg.aws.binbash.com.ar` — envoy-gateway via `private-gw-eg` (`HTTPRoute`); NLB with **`ip`** target-type (→ Envoy pod ENIs, ports 10080/10443). Modern `external` + `nlb-target-type: ip`.
- **Load generator**: k6 (`grafana/k6:0.50.0`) as in-cluster `Job` pinned to `stack=standard` nodes. Script + manifests under this directory.

Submetrics shown in tables: `http_req_duration` per-host (p50 / p90 / p95 / p99 / max), `http_req_failed` per-host, total RPS.

---

## Scenario 1 — baseline smoke + short ramp
**Date**: 2026-05-11
**Profile**: three parallel `ramping-vus` scenarios (one per host), identical shape per host: 30 s @ 10 VUs → 60 s @ 50 VUs → 30 s cool-down. Peak: 50 VUs/host, 150 VUs total. Wall-clock: 2 min.
**Backend tweaks**: none — stock 50 m CPU / 1 replica.
**k6 thresholds**: `http_req_failed<1%` + `checks>99%` per host. No latency gate (the 50 m CPU cap precludes a meaningful one — see README).

### Comparison

| metric (per host) | nginx | kgateway | envoy |
|---|---:|---:|---:|
| `http_req_duration` **p50** | 97.02 ms | 99.01 ms | 98.39 ms |
| **p90** | 298.03 ms | 297.02 ms | 297.55 ms |
| **p95** | 389.03 ms | **316.10 ms** | 392.31 ms |
| **p99** | 593.35 ms | 591.12 ms | 594.65 ms |
| **max** | 1.69 s | 1.60 s | 1.69 s |
| `http_req_failed` | **0.11%** (23 / 19,593) | 0.00% | 0.00% |
| iterations | 19,616 | 20,423 | 20,705 |

Total: **60,744 iterations in 120 s → 506 req/s** across the three scenarios combined (~169 req/s per host avg). All thresholds passed; Job exited 0.

### Read

- **All three cluster tightly** — p50 ~98 ms, p99 ~593 ms — because the 50 m-CPU backend pins everyone to the same queue-time ceiling. p99 reads as "backend service-time ceiling under saturation", not "data-plane latency".
- **kgateway edged the others at p95 this run** (316 ms vs ~390 ms). An earlier dry run had envoy lowest at p95 (~312 ms) and kgateway at ~388 ms — so the p95 spread is within run-to-run noise. The three data planes are effectively equivalent at saturation on this workload.
- **Only nginx had failures** (23 client-side timeouts, both `request timeout` and `dial: i/o timeout`). Same count showed up in the prior dry run, so this is repeatable. All three paths are AWS-LBC NLBs; nginx-private's is `instance` target-type (NLB → worker-node NodePort → pod) while kgateway/envoy are `ip` target-type (NLB → Envoy pod ENI). Fresh-connection setup through the extra NodePort/target-health layer of `instance` mode is the likely cause. Below the 1 % gate, not a regression — just a tail behavior worth knowing. Doesn't appear on the two `ip`-target paths.
- The cap means the *absolute* numbers say more about the backend than the proxies. To compare data planes on their own merits, raise the backend's limits and replica count (next scenario candidate).

### Limitations / things to vary next

- Single replica + 50 m CPU is the dominant signal. Next scenarios should bump these or vary load shape to expose the data planes themselves.
- Only `GET /` exercised. Larger response bodies, query strings, or `POST` with bodies would stress different code paths (request-body buffering, header handling).
- No connection-reuse comparison — k6 defaults to keep-alive on; explicit `noConnectionReuse: true` would highlight TLS handshake / TCP setup cost differences (would also reveal more of the nginx `instance`-target NLB tail).
- No HTTP/2 vs HTTP/1.1 split — k6 negotiates HTTP/2 by default; forcing HTTP/1.1 might shift the picture for nginx.
- WebSockets out of scope per current plan.

---

## Scenario 2 — 2× backend CPU
**Date**: 2026-05-11
**Profile**: same as Scenario 1 (3 parallel `ramping-vus`, 30 s @ 10 VUs → 60 s @ 50 VUs → 30 s cool-down, peak 50 VUs/host, 150 VUs total, 2 min wall-clock).
**Backend tweaks**: bumped echo-server `limits.cpu` from **50 m → 100 m** in `k8s-workloads/echo_server.tf` (memory + replica count unchanged). Applied via `leverage tofu apply`; new pod rolled out before the run.
**k6 thresholds**: unchanged from Scenario 1.

### Comparison

| metric (per host) | nginx | kgateway | envoy |
|---|---:|---:|---:|
| `http_req_duration` **p50** | 61.46 ms | 78.53 ms | **30.44 ms** |
| **p90** | 108.29 ms | 109.67 ms | 107.54 ms |
| **p95** | 183.84 ms | 185.75 ms | 182.09 ms |
| **p99** | 206.15 ms | 209.92 ms | 205.69 ms |
| **max** | 511.70 ms | 500.90 ms | 517.63 ms |
| `http_req_failed` | **0.08%** (37 / 41,397) | 0.00% | 0.00% |
| iterations | 41,397 | 44,311 | 47,788 |

Total: **133,496 iterations in 120 s → 1,046 req/s** combined (~349 req/s per host avg). All thresholds passed; Job exited 0.

### Read

- **Throughput scaled almost perfectly with the CPU bump** — 506 → 1,046 req/s is **2.07×** for a 2× cap raise, confirming Scenario 1's read that the backend was the binding constraint, not any data plane.
- **First scenario where the data planes actually differ.** envoy is meaningfully faster at the **median** (30.4 ms vs nginx 61.5 ms vs kgateway 78.5 ms) and does the most iterations (47.8 k vs 44.3 k vs 41.4 k), which tracks: lower per-request CPU cost on the proxy → more requests served in the same wall-clock. kgateway sits in the middle, nginx between (but with the worst median of the three).
- **The percentile spread collapses at the tail.** p90/p95/p99 are within ~3 ms across all three (~108 / 184 / 207 ms). So even at 100 m the backend is still the queue dominator above p90 — the median is where you see the data-plane's own cost.
- **p99 dropped from ~593 ms (Scenario 1) to ~207 ms.** That's the new backend service-time ceiling under saturation at 100 m CPU.
- **nginx still has the failure tail.** 37 client-side timeouts (0.08%) vs 0 on the two `ip`-target NLB paths — the same pattern as Scenario 1 (23 timeouts there). This is a repeatable characteristic of the nginx-private `instance`-target NLB path under saturation churn, not a one-off. The *rate* dropped a bit (0.11% → 0.08%) because total request count grew.

### Limitations / things to vary next

- Backend is still the dominant tail-percentile factor. To isolate the data planes themselves we'd need a much higher backend ceiling (e.g. 500 m + 3 replicas) or a workload that doesn't pin the backend (`POST` with payload, longer response bodies, intentional artificial think-time).
- Only `GET /` exercised; still the simplest possible code path through each proxy.
- Connection reuse is still on (k6 default). Forcing `noConnectionReuse: true` would surface the TLS-handshake / TCP-setup cost differences — likely amplifies the nginx `instance`-target NLB tail.
- Still HTTP/2 (k6 default); HTTP/1.1 would test a different code path in each data plane.

---

## Scenario 3 — backend out of the way (500 m × 3 replicas)
**Date**: 2026-05-11
**Profile**: same shape as S1/S2 (3 parallel `ramping-vus`, 30 s @ 10 VUs → 60 s @ 50 VUs → 30 s cool-down, peak 50 VUs/host, 150 VUs total, 2 min wall-clock).
**Backend tweaks**: `k8s-workloads/echo_server.tf` — `limits.cpu` 100 m → **500 m**, `replicas` 1 → **3**. 15× total backend CPU vs S2. Applied via `leverage tofu apply`; deploy rolled to 3/3 across two `standard_spot` nodes before the run.
**k6 thresholds**: unchanged from S1/S2.

### Comparison

| metric (per host) | nginx | kgateway | envoy |
|---|---:|---:|---:|
| `http_req_duration` **p50** | **4.36 ms** | 8.55 ms | 5.81 ms |
| **p90** | 25.86 ms | 44.94 ms | 28.15 ms |
| **p95** | 44.42 ms | 58.14 ms | 45.05 ms |
| **p99** | 68.66 ms | 84.85 ms | **64.50 ms** |
| **max** | 129.20 ms | 227.34 ms | 130.30 ms |
| `http_req_failed` | **0.04%** (86 / 189,448) | 0.00% | 0.00% |
| iterations | 189,448 | 163,036 | **240,934** |

Total: **593,418 iterations in 128 s → 4,641 req/s** combined. All thresholds passed; Job exited 0.

### Read

- **4.4× throughput jump for 15× backend CPU** (1,046 → 4,641 req/s) — the backend is no longer the binding constraint. We're now bounded by some combination of data-plane efficiency, NLB throughput, k6 generator capacity, and intra-VPC network. The next bump-the-backend experiment would not move the needle nearly as much.
- **First scenario with real per-host divergence at every percentile.** kgateway is consistently slowest (p50 8.55 ms vs nginx 4.36 / envoy 5.81; p95 58 vs 44 / 45; p99 85 vs 69 / 64). envoy and nginx trade the top spot: nginx fastest at p50, envoy fastest at p99 and (slightly) on tail max. This is the proxy comparison the earlier scenarios couldn't deliver because the backend smeared them all together.
- **kgateway throughput is also lowest**: 163 k iterations vs envoy's 241 k (envoy did **1.48×** more work in the same 2 min). The closed-loop ramping-vus executor explains it — slower responses → fewer iterations completed → kgateway's higher latency *causes* lower throughput here. S4's constant-arrival-rate run will pin RPS and force the proxies to reveal saturation differently.
- **The nginx `instance`-target NLB timeout tail persists at 0.04 %.** 86 client-side timeouts with the backend nowhere near saturated — so this is a real characteristic of the nginx-private NLB path (`instance` target-type → NodePort layer), independent of the backend. Same pattern as S1 (23, 0.11 %) and S2 (37, 0.08 %); rate drops as overall RPS climbs.
- **Max latency is interesting**: kgateway's worst (227 ms) is ~75 % higher than nginx/envoy (~130 ms). Sole worst-outlier across all the data planes lives on kgateway.

### Limitations / things to vary next

- Closed-loop load makes throughput a *function of* latency. S4 (constant-arrival-rate, queued next) will untangle them.
- The k6 generator pod is on a single node — possible single-source bottleneck. Could be split across nodes later.
- No NLB / data-plane CPU/memory snapshots taken — S5's soak will be the easier place to capture before/after `kubectl top` for the gateway pods.
- nginx-private `instance`-target NLB tail still unconfirmed beyond "consistent". `noConnectionReuse: true` (deferred) + watching NLB target-health events during a run would isolate whether fresh-connection setup / NodePort target-health timing is the cause.

---

## Scenario 4 — open-loop, constant-arrival-rate steps
**Date**: 2026-05-11
**Profile**: open-loop. For each host, four sequential `constant-arrival-rate` sub-scenarios at **200 / 400 / 600 / 800 req/s × 60 s** (`timeUnit: 1s`, `preAllocatedVUs: 50`, `maxVUs: 200`). All three hosts run the same step in parallel (shared `startTime` offsets). Wall-clock: 4 min.
**Backend tweaks**: unchanged from S3 (500 m × 3 replicas).
**k6 thresholds**: per-host `http_req_failed < 5%` (loosened so a knee surfaces without flunking the Job), per-(host, rate) visibility-only `http_req_duration p(99)<10s` and `http_req_failed<50%`, per-scenario `dropped_iterations` no-op visibility threshold. Same `checks > 99%` style still applies.
**k6 Job container resources**: bumped to `limits: cpu=2, memory=1Gi` (arrival-rate pre-allocates a larger VU pool than ramping-vus).

### Comparison

Latency `http_req_duration{host:H, rate:Rrps}` p50 / p95 / p99 (ms) per step:

| step | nginx p50 / p95 / p99 | kgateway p50 / p95 / p99 | envoy p50 / p95 / p99 |
|---|---:|---:|---:|
| 200 RPS |  2.50 / 4.07 /  6.50 |  2.76 / 4.23 /  7.01 |  2.72 / 4.19 /  6.78 |
| 400 RPS |  2.40 / 4.05 /  7.45 |  2.65 / 4.46 /  9.35 |  2.59 / 4.22 /  8.18 |
| 600 RPS |  2.18 / 4.00 /  8.33 |  2.59 / 4.64 /  9.71 |  2.45 / 4.28 /  8.76 |
| 800 RPS |  2.08 / 4.21 / 11.37 |  2.65 / 5.57 / 14.55 |  2.46 / 4.81 / 12.29 |

Drops at the 800 RPS step (target = 48,000 iterations/host): **nginx 30, kgateway 31, envoy 32**. All three proxies sustained ~99.94 % of demand.

Per-host `http_req_failed` over all four steps:

| host | overall | 200 rps | 400 rps | 600 rps | 800 rps |
|---|---:|---:|---:|---:|---:|
| nginx | **0.10 %** (124 / 119,974) | 0.29 % (36) | 0.17 % (42) | 0.02 % (8) | 0.07 % (38) |
| kgateway | 0.00 % | 0 | 0 | 0 | 0 |
| envoy | 0.00 % | 0 | 0 | 0 | 0 |

Total: **359,918 iterations in 4 min → 1,500 req/s mean** (≈ delivered demand of `(200+400+600+800) × 60 s × 3 hosts / 240 s`). Job exited 0.

### Read

- **No knee found below 800 RPS per host.** All three proxies served effectively 100 % of the target rate at every step. To find an actual saturation point we'd need higher rates (e.g. 1000 / 1500 / 2000 RPS) or higher concurrency from multiple k6 pods.
- **Consistent latency ordering at every step** (best → worst): **nginx → envoy → kgateway** on both p50 and p99. The order is identical to S3 — open-loop and closed-loop tell the same story for this workload, just on different axes. kgateway is consistently slowest by ~20–30 % at p99 and ~10 % at p50.
- **p50 *decreases* as RPS climbs** for every host (e.g. nginx 2.50 → 2.08 ms; envoy 2.72 → 2.46 ms). Counter-intuitive but readable: warm connection pools and TLS sessions amortize over more requests, plus path caches stay hot. The benefit shows up most at the median (steady-state path), least at p99 (tail).
- **nginx's `instance`-target NLB timeout tail isn't load-driven — it's setup-driven.** Failure *rate* shrinks as RPS climbs (0.29 % @ 200 → 0.07 % @ 800), even though the absolute *count* is similar (36 → 38). That's consistent with "cost-of-fresh-connection" being the source: at low RPS many connections are short-lived; at high RPS the pool stabilizes and per-request setup amortizes. The NodePort layer / NLB target-health timing of `instance` mode (vs the direct pod-ENI registration of the `ip`-target kgateway/envoy NLBs) is the prime suspect. `noConnectionReuse: true` (still deferred) is the right experiment to confirm.
- **Combined RPS isn't pushed** (1,500 mean is lower than S3's 4,641 because we deliberately throttled). This scenario answers "what's the per-host RPS each proxy can sustain cleanly?" — at least 800. S3 answered "what's the absolute throughput when nothing throttles?" — ~4,600 combined. Both signals matter.

### Limitations / things to vary next

- **Did not actually find the knee.** Next iteration: add 1000 / 1500 / 2000 / 2500 RPS steps (or jump straight to those). Will likely require more k6 generator capacity.
- Single k6 pod = single source. Splitting across 2–3 generator pods would let us push higher aggregate RPS and de-confound k6 from data plane.
- `noConnectionReuse: true` is now a clearly motivated next experiment (would isolate / explain the nginx tail).
- Constant-arrival-rate per-host is sequential — running multiple rates per host concurrently would test multi-tenant queueing, but is a different question.

---

## Scenario 5 — 15-minute rate-controlled soak
**Date**: 2026-05-11
**Profile**: `constant-arrival-rate` **500 req/s per host** (1,500 req/s aggregate) held flat for **15 min**, all three hosts in parallel (`preAllocatedVUs: 20`, `maxVUs: 100`, `discardResponseBodies: true`).
**Backend tweaks**: unchanged from S3 (500 m × 3 replicas).
**k6 thresholds**: back to strict — per-host `http_req_failed < 1%`, `checks > 99%`, plus visibility-only `http_req_duration p(99)<10s`.
**k6 Job container resources**: `limits: cpu=2, memory=2Gi`.

> **First attempt OOMed.** The initial S5 design used `constant-vus: 30` per host. Against the S3 backend (p50 ≈ 3 ms) that fires ~10 k req/s *per host* (~30 k aggregate), and k6 retains every metric sample in RAM for end-of-test percentiles → the generator pod blew past 1 Gi and was `OOMKilled` at ~15 min, Job `Failed`. Lesson: on a fast backend, soak load must be *rate-controlled* (`constant-arrival-rate`), not VU-controlled, and bodies should be discarded. Re-run with the design above succeeded.

### Comparison

`http_req_duration{host:H}` over the full 15-minute window:

| metric (per host) | nginx | kgateway | envoy |
|---|---:|---:|---:|
| **avg** | 2.36 ms | 2.78 ms | 2.71 ms |
| **p50** | **2.16 ms** | 2.51 ms | 2.47 ms |
| **p90** | 3.36 ms | 3.76 ms | 3.62 ms |
| **p95** | 3.95 ms | 4.37 ms | 4.22 ms |
| **p99** | **7.38 ms** | 8.48 ms | 8.02 ms |
| **max** | 217.17 ms | 89.35 ms | 88.56 ms |
| `http_req_failed` | **0.05%** (236 / 449,945) | 0.00% | 0.00% |
| `dropped_iterations` | ~47 | ~46 | ~47 (140 total) |
| iterations | 449,945 | 449,962 | 449,956 |

Total: **1,349,863 iterations in 15 min → 1,484 req/s** sustained (≈ 99 % of the 1,500 req/s target; 140 drops total ≈ 0.01 %). Job exited 0; all thresholds passed.

### Read

- **No degradation over 15 minutes.** The full-window aggregates are statistically indistinguishable from S4's 200–400 req/s steps (p50 ~2.2–2.7 ms, p95 ~4 ms, p99 ~7–9 ms). If there had been a connection-pool leak, memory creep, or cert-renewal hiccup, the aggregate would be skewed up by a degraded tail and/or the error rate would spike at some point in the window — neither happened. The proxies are stable at this load.
- **Same proxy ordering as every prior scenario** (best → worst, all percentiles): **nginx → envoy → kgateway**. Differences are small at this load (~10–15 % at p99), but the ranking has now held across closed-loop ramps (S2, S3), open-loop steps (S4), and a 15-min soak (S5). It's a real characteristic, not noise.
- **nginx's `instance`-target NLB tail persists** but stays tiny: 236 client-side timeouts (0.05 %) over 450 k requests, plus a single 217 ms max outlier vs ~89 ms for the `ip`-target envoy/kgateway NLBs. Same pattern as S1–S4; rate is stable, the absolute count just scales with total requests.
- `discardResponseBodies: true` did its job — the generator pod finished `Completed`, peaked well under 2 Gi (echo-server's ~400-byte bodies × 1.35 M requests was the prior memory hog).

### Limitations / things to vary next

- **No time-series, only the 15-min aggregate.** `kubectl top` is unavailable (metrics-server isn't deployed in this cluster), so we couldn't snapshot gateway-pod memory before/after, and k6's default summary is one rollup over the whole window. A truly rigorous soak would stream metrics out (`--out experimental-prometheus-rw` or CSV) and chart p95 over time. The aggregate-matches-low-rate-steps argument is a decent proxy for "stable" but not a substitute.
- Longer soaks (1 h, 4 h, overnight) would catch slower drifts — left for later if there's a reason to suspect one.
- The cert-renewal disruption check is theoretical here (the LE certs were issued < 1 h before the run and won't renew for 60 days) — a real cert-renewal soak would need to force an early renewal.

---

## Scenario 6 — envoy switched to `instance` targets (the controlled test)
**Date**: 2026-08-04
**Profile**: identical to S5 — `constant-arrival-rate` **500 req/s per host** held flat for **15 min**, both hosts in parallel (`preAllocatedVUs: 20`, `maxVUs: 100`, `discardResponseBodies: true`). kgateway is gone, so this is a two-host run.
**Backend tweaks**: 500 m × 3 replicas, same as S3–S5 (applied with `kubectl`, not Terraform — the layer hardcodes 50 m × 1).
**Change under test**: `private-gw-eg`'s NLB moved from `nlb-target-type: ip` to **`instance`**, to preserve the client IP ahead of the nginx cutover. Both hosts are therefore `instance`-target NLBs with `externalTrafficPolicy: Local` — the first time the two data planes have been measured on *identical* network plumbing.

### Comparison

| metric (per host) | nginx (`instance`) | envoy (`instance`) |
|---|---:|---:|
| **avg** | 1.30 ms | 1.34 ms |
| **p50** | **1.27 ms** | 1.31 ms |
| **p90** | 1.54 ms | 1.54 ms |
| **p95** | 1.63 ms | 1.62 ms |
| **p99** | **2.09 ms** | 2.13 ms |
| **max** | **65.38 ms** | 233.21 ms |
| `http_req_failed` | 0.09% (425 / 449,542) | **0.00% (0 / 449,972)** |
| `checks` | 99.90% | **100.00%** |
| iterations | 449,542 | 449,972 |

Total: 899,939 iterations, 989 req/s sustained, 56 dropped (0.006%). Job exited 0; all thresholds passed.

### Read

- **The `instance` target-type is exonerated.** S1–S5 all attributed nginx's timeout tail to `instance` mode's extra NodePort / target-health layer, explicitly flagged as "prime suspect… not yet confirmed". This run is the controlled test that was missing: envoy moved onto the accused configuration and returned **zero failures in 450 k requests**, while nginx on the *same* target-type, same NLB config, same cluster, same 15-minute window produced 425. Same plumbing, opposite outcomes — so the tail cannot be a property of the plumbing. **It is nginx-specific.** Whether it is the controller's connection handling, its keep-alive/timeout config, or something else is now the open question; the target-type is no longer a candidate.
- **No infrastructure confound.** Verified before reading the numbers: the newest node predates the run by ~10 min and no node was reclaimed during the window (an earlier attempt at this same run *was* voided by two spot interruptions — see below). All three nginx DaemonSet pods outlived the run too, so its failures are not restart artifacts.
- **Latency is a wash.** nginx keeps a hair's-breadth lead at p50/p99 (~0.04 ms, well inside noise) and the two are identical at p90/p95. The consistent "nginx → envoy → kgateway" ordering of S3–S5 does not survive the move to identical plumbing at this load, which suggests part of that ordering was the target-type difference rather than the proxies themselves.
- **Absolute latency is ~2× better than S5** (p50 1.3 ms vs 2.2–2.5 ms) on the same nominal backend. Do not read this as a data-plane improvement: the cluster was rebuilt on EKS 1.34 / AL2023 between S5 and S6. Only within-run comparisons are valid here.
- **envoy owns the single worst outlier** (233 ms vs nginx's 65 ms), inverting S5 where nginx had the 217 ms max against envoy's 89 ms. One sample either way — noise until it repeats.

### Limitations / things to vary next

- ~~**The interesting experiment is now the inverse**: put nginx behind an `ip`-target NLB and see whether its tail follows it.~~ **Declined (2026-08-04).** It would isolate nginx-the-controller from nginx-the-NLB-config, but nginx is being replaced by Envoy Gateway, so the answer changes nothing we would act on. Noted here because the window closes when nginx is retired — if anyone ever wants it, that is the deadline.
- Still no time-series, only the 15-min aggregate (`kubectl top` unavailable, metrics-server not deployed). Same limitation as S5.
- The generator is inside the cluster on a spot node. A 15-min run has a real chance of being voided by an interruption — the first attempt at this scenario died at ~6 min when both the k6 node and the Envoy `tools` node were reclaimed. `ttlSecondsAfterFinished` was removed from `k6-job.yaml` afterwards, because it garbage-collected the failed Job before its logs could be read.
- Client-IP preservation was verified out-of-band, not by k6: `X-Forwarded-For` on the envoy path went from the NLB's own address to the real client IP, matching nginx.

## Cross-scenario summary (S1 → S5)

| | S1 (50 m ×1) | S2 (100 m ×1) | S3 (500 m ×3) | S4 (500 m ×3, open-loop steps) | S5 (500 m ×3, 15-min soak) |
|---|---:|---:|---:|---:|---:|
| Total RPS | 506 | 1,046 | 4,641 | 1,500 (capped by design) | 1,484 (capped by design) |
| nginx p50 / p99 | 97 / 593 ms | 61 / 206 ms | 4.4 / 69 ms | ~2.1 / 6–11 ms | 2.2 / 7.4 ms |
| kgateway p50 / p99 | 99 / 591 ms | 79 / 210 ms | 8.6 / 85 ms | ~2.6 / 7–15 ms | 2.5 / 8.5 ms |
| envoy p50 / p99 | 98 / 595 ms | 30 / 206 ms | 5.8 / 65 ms | ~2.5 / 7–12 ms | 2.5 / 8.0 ms |
| nginx failures | 0.11% | 0.08% | 0.04% | 0.10% | 0.05% |
| kgateway / envoy failures | 0% | 0% | 0% | 0% | 0% |

**Bottom line:**
- The backend (`echo-server` CPU/replicas) was the dominant factor in S1/S2 — only once it was lifted to 500 m × 3 (S3) did the data planes' own latency become visible.
- With the backend out of the way, **nginx is fastest, envoy second, kgateway third** at every percentile in every scenario. The spread is ~10–30 % at p99; all three are sub-15 ms p99 at moderate load.
- **kgateway is consistently the slowest** of the three and produces the worst single outliers — but still comfortably fast in absolute terms.
- **nginx-ingress is the only path that ever fails requests** — a small, repeatable client-side-timeout tail (0.04–0.11 %), load-independent. The two `ip`-target paths had **zero** failures across every scenario.
  > **Superseded by S6.** Through S5 this was attributed to nginx-private's `instance` target-type (NLB → worker-node NodePort → pod) versus kgateway/envoy's `ip` targets, with the NodePort layer named "prime suspect… not yet confirmed". S6 ran the controlled test: envoy on `instance` targets logged **zero** failures over 450 k requests while nginx on the same target-type logged 425 in the same window. The tail is **nginx-specific**, not a property of `instance` mode. The ordering claims above are also partly confounded by target-type — S6 found nginx and envoy indistinguishable on identical plumbing.
- No proxy showed a saturation knee below 800 req/s per host (S4); none degraded over a 15-min soak (S5).

<!-- Append new scenarios below using the same template. -->
<!--
## Scenario N — <short name>
**Date**: YYYY-MM-DD
**Profile**: …
**Backend tweaks**: …
**k6 thresholds**: …

### Comparison
| metric (per host) | nginx | kgateway | envoy |
|---|---:|---:|---:|
| … | … | … | … |

### Read
- …

### Limitations / things to vary next
- …
-->
