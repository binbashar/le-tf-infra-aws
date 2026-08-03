#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
ingress = {
  alb_controller = {
    enabled = true
  }

  # ########################
  # CAN NOT SET BOTH TO TRUE
  nginx_controller = {
    enabled = true
  }
  traefik = {
    enabled = false
  }
  # ########################

  # create an ingress to send traffic from ALB to Nginx/Traefik
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
#------------------------------------------------------------------------------
external_secrets = {
  enabled = false
}

#------------------------------------------------------------------------------
# Scaling
#------------------------------------------------------------------------------
scaling = {
  hpa = {
    enabled = false
  }

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
# Private path: EG-provisioned Envoy fronted by an LBC-managed internal NLB,
# GatewayClass `envoy-gateway` in namespace `envoy-gateway-system`. Workload
# HTTPRoutes attach via cross-namespace parentRef pointing at `private-gw-eg`.
#------------------------------------------------------------------------------
envoy_gateway = {
  enabled             = true
  version             = "v1.7.2"
  gateway_api_version = "v1.4.0"

  private_gateway = {
    enabled = true
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
  enabled = false

  enableWebTerminal   = true
  enableNotifications = false

  image_updater = {
    enabled = false
  }

  rollouts = {
    enabled = false

    dashboard = {
      enabled = false
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
