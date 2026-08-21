#=============================#
# Layer Flags                 #
#=============================#
variable "ingress" {
  type = object({
    alb_controller = map(any)
    traefik        = map(any)
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

# Envoy Gateway is the Gateway API data plane for this layer and the chosen
# replacement for nginx-ingress. `gateway_api_version` pins the upstream
# Gateway API CRD bundle shared by any Gateway API consumer — it lives here
# rather than in a data-plane-specific variable, see networking-gateway-api.tf.
#
# Two Gateways can be provisioned independently, each with its own GatewayClass,
# EnvoyProxy and NLB (Envoy Gateway provisions one data plane per Gateway):
#   - private_gateway: internal NLB, VPN-only, *.aws.binbash.com.ar
#   - public_gateway:  internet-facing NLB, *.binbash.com.ar, locked down to
#     `allowed_cidrs` at the NLB security group.
variable "envoy_gateway" {
  type = object({
    enabled             = bool
    version             = string
    gateway_api_version = string
    private_gateway = object({
      enabled = bool
    })
    public_gateway = object({
      enabled = bool
      # Which AWS load balancer fronts the public gateway.
      #
      #   "nlb" — an internet-facing NLB provisioned by the Envoy Gateway
      #           controller from the Gateway's own Service. TLS terminates in
      #           Envoy off the `*.binbash.com.ar` wildcard, and the CIDR
      #           allowlist is enforced on the NLB's frontend security group.
      #
      #   "alb" — no Service-provisioned load balancer at all: the Gateway's
      #           Service drops to ClusterIP and an Ingress asks the AWS Load
      #           Balancer Controller for an ALB in front of it. TLS terminates
      #           on the ALB off an ACM certificate, and the allowlist moves to
      #           the ALB's `inbound-cidrs`.
      #
      # The two are mutually exclusive by construction, so flipping this one
      # word is the whole rollback. "alb" mirrors the topology this cluster is
      # modelled on (ALB + ACM + WAF in front of the ingress data plane); see
      # README.md.
      frontend = string
      # Whether the frontend admits the whole internet instead of
      # `envoy_gateway_public_allowed_cidrs`.
      #
      # True is what the modelled topology actually runs: the perimeter is open
      # and access control lives per-application, as a SecurityPolicy on each
      # route (see k8s-workloads). Keeping the perimeter closed as well is
      # defence in depth, but it is also a second place to forget, and it masks
      # whether the per-route filtering really works.
      #
      # This flag exists so that "open" is a decision someone wrote down. The
      # same state is otherwise reachable by leaving the CIDR list empty, which
      # is indistinguishable from having forgotten to fill it in.
      open_to_internet = bool
      # Whether to attach the AWS WAF WebACL published by the
      # `apps-devstg/us-east-1/security-firewall --` layer to the ALB frontend.
      # That layer carries the ` --` exclusion because the WebACL is held ready
      # rather than deployed; turning this on means renaming it out of the
      # exclusion and applying it first (its backend key does not change).
      #
      # Only meaningful with `frontend = "alb"` — WAF does not attach to an NLB,
      # which is the constraint that made the ALB the target rather than the
      # obstacle (see README.md). A precondition rejects the combination instead
      # of silently ignoring it.
      #
      # Turning this on makes this layer read the firewall layer's remote state,
      # so that layer has to be applied first. Off, the data source is not read
      # at all and the layer plans standalone.
      waf_enabled = bool
    })
  })
  default = {
    enabled             = false
    version             = "v1.7.2"
    gateway_api_version = "v1.4.0"
    private_gateway = {
      enabled = false
    }
    public_gateway = {
      enabled          = false
      frontend         = "nlb"
      open_to_internet = false
      waf_enabled      = false
    }
  }

  validation {
    condition     = contains(["nlb", "alb"], var.envoy_gateway.public_gateway.frontend)
    error_message = "envoy_gateway.public_gateway.frontend must be either \"nlb\" or \"alb\"."
  }

  validation {
    condition     = !var.envoy_gateway.public_gateway.waf_enabled || var.envoy_gateway.public_gateway.frontend == "alb"
    error_message = "envoy_gateway.public_gateway.waf_enabled requires frontend = \"alb\": AWS WAF cannot attach to an NLB."
  }
}

# Source CIDRs allowed to reach the public gateway's internet-facing frontend.
#
# Deliberately NOT set in the versioned `terraform.tfvars`: the list is made of
# operators' home/office addresses, which are personal data and don't belong in
# git history. Populate it in `allowlist.local.auto.tfvars`, which OpenTofu
# auto-loads and `.gitignore` excludes — copy
# `allowlist.local.auto.tfvars.example` to get started.
#
# Consulted only while `envoy_gateway.public_gateway.open_to_internet` is false.
# When it is true — the modelled topology — `local.public_gw_eg_source_ranges`
# short-circuits to 0.0.0.0/0 and this list goes unread; access control then
# lives per application, as a SecurityPolicy on each route.
#
# In the closed state it is rendered into whichever allowlist the frontend
# offers: `load-balancer-source-ranges`, which the AWS Load Balancer Controller
# turns into ingress rules on the NLB's managed frontend security group under
# `frontend = "nlb"`, or the Ingress' `inbound-cidrs` under `frontend = "alb"`.
# An EMPTY list there makes the LBC fall back to 0.0.0.0/0 and expose the
# endpoint to the whole internet, so preconditions in networking-envoygateway.tf
# and networking-ingress.tf refuse to plan in that state.
#
# It is a separate top-level variable rather than a field of `envoy_gateway`
# because tfvars files can't merge into an object variable — setting one field
# from a second file would mean restating the whole object.
variable "envoy_gateway_public_allowed_cidrs" {
  description = "CIDRs allowed to reach the public Envoy Gateway frontend (ALB or NLB) while open_to_internet is false. Set in the non-versioned allowlist.local.auto.tfvars."
  type        = list(string)
  default     = []
}
