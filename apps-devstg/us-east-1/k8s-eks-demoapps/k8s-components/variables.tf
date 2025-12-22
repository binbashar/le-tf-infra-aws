#=============================#
# Layer Flags                 #
#=============================#
variable "ingress" {
  type = object({
    alb_controller   = map(any)
    nginx_controller = map(any)
    traefik          = map(any)
    apps_ingress = object({
      enabled = bool
      type    = string
      logging = object({
        enabled = bool
        prefix  = string
      })
    })
  })
  default = {
    alb_controller = {
      enabled = true
    }

    nginx_controller = {
      enabled = true
    }


    traefik = {
      enabled = false
    }

    apps_ingress = {
      enabled = false

      type = "internal"

      logging = {
        enabled = false
        prefix  = ""
      }
    }
  }
}

variable "certmanager" {
  type = map(any)
  default = {
    enabled = true
  }
}

variable "dns_sync" {
  type = map(any)
  default = {
    private = {
      enabled = true
    }

    public = {
      enabled = false
    }
  }
}

variable "external_secrets" {
  type = map(any)
  default = {
    enabled = true
  }
}

variable "scaling" {
  type = map(any)
  default = {
    hpa = {
      enabled = false
    }

    vpa = {
      enabled = false
    }

    cluster_autoscaling = {
      enabled = false
    }

    cluster_overprovisionning = {
      enabled = false
    }
  }
}

variable "goldilocks" {
  type = map(any)
  default = {
    enabled = false
  }
}

variable "logging" {
  type = object({
    enabled    = bool,
    forwarders = list(string)
  })
  default = {
    enabled = false

    forwarders = []
  }
}

variable "prometheus" {
  type = object({
    kube_stack = object({
      enabled      = bool,
      alertmanager = map(any)
    })
    external = map(any)
  })
  default = {
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
}

variable "datadog_agent" {
  type = map(any)
  default = {
    enabled = false
  }
}

variable "kwatch" {
  type = map(any)
  default = {
    enabled = false
  }
}

variable "uptime_kuma" {
  type = map(any)
  default = {
    enabled = false
  }
}

variable "gatus" {
  type = map(any)
  default = {
    enabled = false
  }
}

variable "argocd" {
  type = object({
    enabled             = bool
    enableWebTerminal   = bool
    enableNotifications = bool
    image_updater       = map(any)
    rollouts = object({
      enabled   = bool
      dashboard = map(any)
    })
  })
  default = {
    enabled = true

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
}

variable "cost_optimization" {
  type = map(any)
  default = {
    kube_resource_report = false
    cost_analyzer        = false
  }
}

variable "keda" {
  type = object({
    enabled     = bool
    http_add_on = map(any)
  })
  default = {
    enabled = false
    http_add_on = {
      enabled = false
    }
  }
}
