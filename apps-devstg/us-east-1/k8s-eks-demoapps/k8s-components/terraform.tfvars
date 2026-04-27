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
    enabled = false
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
    enabled = false
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
# Ingress: kgateway (test drive — Gateway API based controller, eventual
# replacement for nginx-ingress). Safe to run alongside nginx since kgateway
# uses Gateway API resources, not Ingress resources.
#------------------------------------------------------------------------------
kgateway = {
  enabled               = true
  version               = "v2.2.3"
  gateway_api_version   = "v1.4.0"
  experimental_features = false

  # Shared private path: kgateway-provisioned Envoy fronted by an LBC-managed
  # internal NLB. Workload HTTPRoutes attach via cross-namespace parentRef.
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
