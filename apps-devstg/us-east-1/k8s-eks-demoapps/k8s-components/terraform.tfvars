#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
ingress = {
  alb_controller = {
    enabled = true
  }

  # The last Ingress-API controller in this layer, and off. nginx-ingress used
  # to sit beside it as a mutually exclusive alternative and was removed
  # outright — replacing it is the whole point of this cluster, so it is never
  # coming back. Since the nginx → Envoy Gateway migration, private L7 traffic
  # goes through `private-gw-eg` via HTTPRoutes, so nothing watches
  # `private-apps` any more. See the note on `local.private_ingress_class` in
  # locals.tf before enabling this — the components once wired to that class
  # have HTTPRoutes now, not Ingresses.
  # `apps_ingress` below depends on this being on, and is off too.
  traefik = {
    enabled = false
  }

  # create an ingress to send traffic from ALB to Traefik
  apps_ingress = {
    enabled = false
    # Load balancer type: internet-facing or internal
    type = "internal"

    logging = {
      # note if this is true the bucket must exists!
      enabled = false
      prefix  = ""
    }
  }
}

#------------------------------------------------------------------------------
# Certificate Manager
#------------------------------------------------------------------------------
certmanager = {
  enabled = true
}

#------------------------------------------------------------------------------
# External DNS sync
#------------------------------------------------------------------------------
dns_sync = {
  private = {
    enabled = true
  }

  public = {
    enabled = true
  }
}

#------------------------------------------------------------------------------
# Secrets Management
#
# On because the google-microservices demo asks for it: its kustomize base
# ships an `ExternalSecret` pointing at the `cluster-secrets-manager`
# ClusterSecretStore this flag creates, and `paymentservice` reads the Secret it
# produces through a `secretKeyRef` with no `optional`, so the pod never starts
# without it. Source value is `/k8s-eks-demoapps/test-secrets` in this account,
# owned by the `secrets` layer.
#------------------------------------------------------------------------------
external_secrets = {
  enabled = true
}

#------------------------------------------------------------------------------
# Scaling
#------------------------------------------------------------------------------
scaling = {
  hpa = {
    enabled = false
  }

  # Off with goldilocks, which was its only consumer — VPA has no recommender
  # of its own and nothing else reads the VPA objects. Note this flag also
  # gates metrics-server (see the `helm_release.metrics_server` count
  # expression), so turning it off takes `kubectl top` with it. Nothing else
  # depends on that today: HPA is off above.
  vpa = {
    enabled = false
  }

  cluster_autoscaling = {
    enabled = true
  }

  cluster_overprovisioning = {
    enabled = false
  }
}

#------------------------------------------------------------------------------
# Scaling: Goldilocks
#------------------------------------------------------------------------------
goldilocks = {
  enabled = false
}


#------------------------------------------------------------------------------
# Scaling: Keda
#------------------------------------------------------------------------------
keda = {
  enabled = false

  http_add_on = {
    enabled = false
  }
}

#------------------------------------------------------------------------------
# Ingress: Envoy Gateway (CNCF, Gateway API based). Chosen as the replacement
# for nginx-ingress after benchmarking it against kgateway and nginx — see
# loadtest/test-results.md. Runs alongside nginx during the migration since it
# consumes Gateway API resources, not Ingress ones.
#
# `gateway_api_version` pins the shared upstream Gateway API CRD bundle
# (Gateway, HTTPRoute, GatewayClass, …) — see networking-gateway-api.tf.
#
# Two independent Gateways, each with its own GatewayClass, EnvoyProxy and NLB
# (EG provisions one Envoy data plane per Gateway), both in the
# `envoy-gateway-system` namespace. Workload HTTPRoutes pick one via a
# cross-namespace parentRef:
#
#   private_gateway -> `private-gw-eg`, GatewayClass `envoy-gateway`
#     Internal NLB, VPN-only. Hostnames: <app>.aws.binbash.com.ar
#     Accepts HTTPRoutes from any namespace.
#
#   public_gateway  -> `public-gw-eg`, GatewayClass `envoy-gateway-public`
#     Internet-facing ALB (see `frontend` below), open at the perimeter, with
#     access control per application as a SecurityPolicy on each route.
#     Hostnames: <app>.binbash.com.ar
#     Accepts HTTPRoutes ONLY from namespaces labelled
#     `gateway.binbash.com.ar/public-exposure=allowed`.
#
# The public allowlist is NOT set here: it holds operators' home/office IPs,
# which shouldn't land in git history. It lives in the non-versioned
# `allowlist.local.auto.tfvars` — copy `allowlist.local.auto.tfvars.example`
# and fill it in. It is only consulted while `open_to_internet = false`, which
# is not the modelled topology; in that state, planning the public gateway
# without it fails on a precondition rather than exposing an open endpoint.
#------------------------------------------------------------------------------
envoy_gateway = {
  enabled             = true
  version             = "v1.7.2"
  gateway_api_version = "v1.4.0"

  private_gateway = {
    enabled = true
  }

  # `frontend = "alb"` puts an ALB with an ACM certificate in front of the
  # gateway and drops its Service to ClusterIP, replacing the internet-facing
  # NLB. This is the topology the cluster is modelled on; "nlb" is the previous
  # shape and flipping this one word is the whole rollback.
  # `open_to_internet` matches the modelled topology: the ALB admits everyone
  # and access control lives per-application, as a SecurityPolicy on each route
  # (see k8s-workloads). Set it back to false to also close the perimeter to
  # `envoy_gateway_public_allowed_cidrs` — useful while a route's own policy is
  # still being written, but note it then masks whether that policy works.
  # `waf_enabled` attaches the WebACL owned by the `security-firewall --` layer,
  # which is excluded from the deployed set and must be renamed out of that
  # exclusion and applied first. Every rule in it currently runs in COUNT, so it
  # observes and logs without blocking; promoting rules to `block` is a change
  # in that layer, not here.
  public_gateway = {
    enabled          = true
    frontend         = "alb"
    open_to_internet = true
    waf_enabled      = false
  }
}

#------------------------------------------------------------------------------
# Monitoring: Logging
#------------------------------------------------------------------------------
logging = {
  enabled = false
  # Log forwarders/processors
  # When logging is enabled fluent-bit is enabled also
  forwarders = [
    "fluentd-awses",
    "fluentd-selfhosted",
    "k8s-event-logger"
  ]
}

#------------------------------------------------------------------------------
# Monitoring: Prometheus
#------------------------------------------------------------------------------
# KubePrometheusStack
prometheus = {
  kube_stack = {
    enabled = false

    # Off because the secret its only receiver needs,
    # `/notifications/alertmanager` in the shared account, does not exist —
    # `helm_release.kube_prometheus_stack` reads it through a
    # `data.aws_secretsmanager_secret_version`, so flipping this without
    # creating the secret fails the plan. The chart values are gated on this
    # same flag, so Alertmanager and its HTTPRoute both stay absent rather than
    # rendering a workload with an empty `slack_api_url`.
    alertmanager = {
      enabled = false
    }
  }

  external = {
    dependencies = {
      enabled = false
    }
    grafana_dependencies = {
      enabled = false
    }
  }
}

#------------------------------------------------------------------------------
# Monitoring: Datadog (logs, metrics, and more)
#------------------------------------------------------------------------------
datadog_agent = {
  enabled = false
}

#------------------------------------------------------------------------------
# Monitoring: Alerts
#------------------------------------------------------------------------------
# KWatch
kwatch = {
  enabled = false
}

#------------------------------------------------------------------------------
# Monitoring: Uptime Kuma
#------------------------------------------------------------------------------
uptime_kuma = {
  enabled = false
}

#------------------------------------------------------------------------------
# Monitoring: Gatus
#------------------------------------------------------------------------------
gatus = {
  enabled = false
}

#------------------------------------------------------------------------------
# CICD | Argo
#------------------------------------------------------------------------------
argocd = {
  enabled = true

  enableWebTerminal   = true
  enableNotifications = false

  # Still off. It writes back to the app repositories over git, and with the
  # tags those repos pin today the update would be a no-op anyway — so it would
  # be verified by nothing while being able to commit. Enabling it is its own
  # exercise; see PLATFORM-NOTES.md.
  image_updater = {
    enabled = false
  }

  # Gated independently of `argocd.enabled` above (see cicd-argo.tf), so this
  # has to come down on its own — leaving it true keeps Rollouts and its
  # dashboard installed with no Argo CD alongside them.
  #
  # Required by emojivoto, not optional alongside it: that app's kustomize base
  # declares its workloads as `kind: Rollout`, so without the CRDs this chart
  # installs, the Application syncs to a resource type the API server does not
  # know.
  rollouts = {
    enabled = true

    dashboard = {
      enabled = true
    }
  }
}

#------------------------------------------------------------------------------
# FinOps | Cost Optimizations Tools
#------------------------------------------------------------------------------
cost_optimization = {
  kube_resource_report = false
  cost_analyzer        = false
}
