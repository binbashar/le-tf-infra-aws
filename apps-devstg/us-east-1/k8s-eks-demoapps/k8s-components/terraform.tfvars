#------------------------------------------------------------------------------
# Ingress
#------------------------------------------------------------------------------
ingress = {
  alb_controller = {
    enabled = false
  }

  nginx_controller = {
    enabled = true
  }

  apps_ingress = {
    enabled = false
    # Load balancer type: internet-facing or internal
    type = "internal"

    logging = {
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
  enabled = true
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
    enabled = true

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

  image_updater = {
    enabled = true
  }

  rollouts = {
    enabled = true

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
