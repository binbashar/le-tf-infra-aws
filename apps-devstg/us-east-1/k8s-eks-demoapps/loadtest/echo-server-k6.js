// echo-server-k6.js
// -----------------------------------------------------------------------------
// 15-minute rate-controlled soak of the echo-server data planes:
//
//   echo-server.aws.binbash.com.ar      → nginx-ingress (Ingress, private NLB)
//   echo-server-eg.aws.binbash.com.ar   → envoy-gateway  (HTTPRoute → private-gw-eg)
//
// (A third host, echo-server-kg → kgateway, ran here until kgateway was
// removed in favour of Envoy Gateway; see loadtest/test-results.md for the
// three-way benchmark that informed that call.)
//
// 500 req/s per host (1,000 req/s aggregate) held flat for 15 min, both
// hosts in parallel. A *rate-controlled* soak rather than a VU-controlled one:
// with the S3 backend (500m × 3 replicas, p50 ≈ 3 ms) a `constant-vus` soak
// would fire tens of thousands of req/s and either OOM the generator or melt
// the cluster — `constant-arrival-rate` keeps the load predictable and
// well below the ≥800-req/s-per-host knee that S4 couldn't even find.
//
// `discardResponseBodies: true` — we only check status, never read the body —
// keeps the generator's memory in check over the long window.
//
// Goal: catch only-visible-over-time regressions (connection-pool growth /
// leaks, slow memory creep in the proxies, cert renewal disruption, internal
// connection-state churn) that the 2-minute ramps miss.
// -----------------------------------------------------------------------------

import http from 'k6/http';
import { check } from 'k6';

const HOSTS = {
  nginx: 'https://echo-server.aws.binbash.com.ar/',
  envoy: 'https://echo-server-eg.aws.binbash.com.ar/',
};

const SOAK_RPS      = 500;     // per host
const SOAK_DURATION = '15m';

const scenarios = {};
const thresholds = { 'http_req_failed': ['rate<0.01'] };
Object.keys(HOSTS).forEach((host) => {
  scenarios[host] = {
    executor: 'constant-arrival-rate',
    exec: host,
    rate: SOAK_RPS,
    timeUnit: '1s',
    duration: SOAK_DURATION,
    preAllocatedVUs: 20,
    maxVUs: 100,
    gracefulStop: '10s',
    tags: { host },
  };
  thresholds[`http_req_failed{host:${host}}`]   = ['rate<0.01'];
  thresholds[`http_req_duration{host:${host}}`] = ['p(99)<10000'];  // visibility only
  thresholds[`checks{host:${host}}`]            = ['rate>0.99'];
});

export const options = {
  scenarios,
  thresholds,
  discardResponseBodies: true,
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
  insecureSkipTLSVerify: false,
  noConnectionReuse: false,
};

function hit(url) {
  const r = http.get(url, { timeout: '10s' });
  check(r, { 'status 200': res => res.status === 200 });
}

export function nginx() { hit(HOSTS.nginx); }
export function envoy() { hit(HOSTS.envoy); }
