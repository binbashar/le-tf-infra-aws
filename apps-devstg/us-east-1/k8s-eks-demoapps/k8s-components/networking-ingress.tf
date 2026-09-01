#------------------------------------------------------------------------------
# AWS Load Balancer (Ingress) Controller: Route outside traffic to the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "alb_ingress" {
  count      = var.ingress.alb_controller.enabled ? 1 : 0
  name       = "alb-ingress"
  namespace  = kubernetes_namespace.alb_ingress[0].id
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.4"
  values = [
    templatefile("chart-values/alb-ingress.yaml", {
      clusterName        = data.terraform_remote_state.cluster.outputs.cluster_name,
      vpcId              = data.terraform_remote_state.cluster.outputs.vpc_id,
      region             = var.region,
      ingressClass       = local.public_ingress_class,
      serviceAccountName = "alb-ingress",
      roleArn            = data.terraform_remote_state.cluster-identities.outputs.aws_lb_controller_role_arn,
    })
  ]
}

#------------------------------------------------------------------------------
# Controller Drain Gate
# -----------------------------------------------------------------------------
# This resource exists purely to make `tofu destroy` survivable. It has no
# effect on a normal apply.
#
# THE PROBLEM
# Every object that ends up as a `Service` of type LoadBalancer (the Envoy
# Gateways, the traefik controller) gets the `service.k8s.aws/resources`
# finalizer attached by the AWS Load Balancer Controller. Only the LBC can
# remove that finalizer. If the LBC helm release is destroyed first, the
# Services hang in `Terminating` forever, their namespace never terminates, and
# the destroy fails with `context deadline exceeded`.
#
# WHY `depends_on` ALONE IS NOT ENOUGH
# The Gateways already declare `depends_on = [helm_release.alb_ingress]`, so
# Terraform does delete them before the controllers. That ordering was in place
# during the teardown that deadlocked anyway, because the cleanup is
# *asynchronous*: deleting a `Gateway` returns as soon as the CR is gone, but
# the derived `Service` is garbage collected by the Envoy Gateway controller
# some seconds later, and only then does the LBC get to delete the NLB and
# strip its finalizer. Terraform does not wait for any of that -- it moves
# straight on to destroying the controllers, killing them mid-cleanup.
#
# THE FIX
# `destroy_duration` holds the destroy graph open between the two groups. On
# destroy the order becomes:
#
#   Gateways / ingress controllers  ->  [ wait 180s ]  ->  LBC + Envoy Gateway
#
# which is exactly the window the controllers need to finish garbage collecting.
# The dependency direction is inverted from what reads naturally: this resource
# depends on the *controllers*, and the objects they manage depend on *it*, so
# that Terraform's reverse-order destroy produces the sequence above.
#
# 180s is deliberately generous -- NLB deletion is the slow step and a teardown
# is never time critical.
#------------------------------------------------------------------------------
resource "time_sleep" "controller_drain" {
  count = var.ingress.alb_controller.enabled || var.envoy_gateway.enabled ? 1 : 0

  destroy_duration = "180s"

  depends_on = [
    helm_release.alb_ingress,
    helm_release.envoy_gateway,
  ]
}

#------------------------------------------------------------------------------
# Traefik (Private): Route inside traffic to services in the cluster.
#------------------------------------------------------------------------------
# The only Ingress-API controller left in this layer. It used to be one of a
# mutually exclusive pair with nginx-ingress, which is why the count read
# `!nginx && traefik`; nginx is gone and the exclusion went with it.
#------------------------------------------------------------------------------
resource "helm_release" "traefik" {
  count      = var.ingress.traefik.enabled ? 1 : 0
  name       = "traefik-ingress-private"
  namespace  = kubernetes_namespace.traefik_ingress[0].id
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  version    = "37.4.0"
  values = [
    templatefile("chart-values/traefik.yaml", {
      ingressClass = local.private_ingress_class,
      tags         = join(",", local.traefik_tags_list)

    })
  ]

  # Owns a Service of type LoadBalancer, so it must be torn down before the LBC
  # -- see the drain gate above.
  depends_on = [
    time_sleep.controller_drain,
  ]
}

#------------------------------------------------------------------------------
# Apps Ingress ALB2Traefik
# -----------------------------------------------------------------------------
# This ingress object defines the attributes of an Application Load Balancer
# (ALB) which will be created by the ALB Ingress Controller. Such LB will serve
# as an entrypoint for traffic that needs to reach any services hosted in the
# cluster.
# When using an internet-facing ALB, the traffic flow will work as follows:
#
#   Internet => ALB => Traefik (pods) => App (service)
#
# There is also the option to use an internal ALB, in which case the traffic
# will work like this:
#
#   VPN => ALB => Traefik (pods) => App (service)
#
#------------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "traefik_apps" {
  count                  = var.ingress.apps_ingress.enabled && var.ingress.alb_controller.enabled && var.ingress.traefik.enabled ? 1 : 0
  wait_for_load_balancer = true

  metadata {
    name      = "apps"
    namespace = kubernetes_namespace.traefik_ingress[0].id
    annotations = {
      # This is used by the ALB Ingress
      # This annotation is deprecated in newer K8s versions as per https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation
      # Use spec.ingressClassName (ingress_class_name) instead
      # "kubernetes.io/ingress.class" = "${local.public_ingress_class}"

      # Load balancer type: internet-facing or internal
      "alb.ingress.kubernetes.io/scheme" = var.ingress.apps_ingress.type
      # Group this LB under a custom group so it's not shared with other groups
      "alb.ingress.kubernetes.io/group.name" = "apps"
      # Traefik provides an endpoint for health checks
      "alb.ingress.kubernetes.io/healthcheck-path" = "/ping"
      # Use the AWS ACM certificate we created for this
      "alb.ingress.kubernetes.io/certificate-arn" = data.terraform_remote_state.certs.outputs.certificate_arn
      # Enable ports 80 and 443
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      # Define the SSL Redirect action
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\" } }"
      # Use HTTPS as we are forwarding to the https port of the traefik service
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      # Define resource tags
      "alb.ingress.kubernetes.io/tags" = join(",", local.alb_ingress_to_private_ingress_tags_list)
      # Filter traffic by IP addresses
      # NOTE: this is highly recommended when using an internet-facing ALB
      "alb.ingress.kubernetes.io/inbound-cidrs" = "0.0.0.0/0"
      # ALB access logs
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "${local.load_balancer_attributes}"
    }
  }

  spec {
    ingress_class_name = local.public_ingress_class
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "ssl-redirect"
              port {
                name = "use-annotation"
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "traefik-ingress-private"
              port {
                number = 443
              }
            }
          }
        }

      }
    }
  }

  depends_on = [
    helm_release.alb_ingress,
    helm_release.traefik,
    # Backs an ALB provisioned by the LBC, which is likewise deleted
    # asynchronously -- see the drain gate above.
    time_sleep.controller_drain,
  ]
}

#------------------------------------------------------------------------------
# Apps Ingress: ALB in front of the public Envoy Gateway
# -----------------------------------------------------------------------------
# Only under `envoy_gateway.public_gateway.frontend = "alb"`. This is the
# topology the cluster is modelled on -- an ALB terminating TLS with an ACM
# certificate in front of an in-cluster ingress data plane, which then carries
# its own routing and (later) its own TLS to the workloads:
#
#   Internet => ALB (ACM, WAF) => Envoy Gateway (pods) => App (service)
#
# It replaces the internet-facing NLB the Gateway's own Service would otherwise
# provision; the two never coexist. Compare `traefik_apps` above, which is the
# same shape with a different data plane behind the ALB.
#
# Four annotations carry most of the design:
#
#   group.name       -- distinct from `apps`. The LBC merges every Ingress
#                       sharing a group onto ONE ALB, so reusing the name would
#                       mutate the existing balancer rather than provision a
#                       dedicated one. The group name is baked into the ALB's
#                       name and tags, so changing it later recreates the ALB.
#   healthcheck-path -- `/healthz`, answered by a fixed-200 route on the gateway
#                       (see networking-envoygateway.tf). Envoy returns 404 for
#                       an unmatched path, so the default `/` would fail the
#                       check on a perfectly healthy gateway.
#   inbound-cidrs    -- the same allowlist the NLB frontend puts on its security
#                       group. The reference topology leaves the ALB open and
#                       filters per-application further in; this keeps the
#                       endpoint closed until that per-route filtering exists.
#   wafv2-acl-arn    -- the WebACL from the `security-firewall --` layer, added
#                       only under `public_gateway.waf_enabled`. The controller
#                       makes the association, because nothing that plans before
#                       the ALB exists can know its ARN. See
#                       `local.envoy_apps_waf_annotations`.
#
# `backend-protocol` stays HTTP: the ALB terminates TLS and forwards cleartext
# to the gateway's `http` listener. Moving to HTTPS is what the reference
# topology actually does, and it needs the health check rethought first --
# ALB health checks send no SNI, which an HTTPS listener with a hostname may
# refuse.
#------------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "envoy_apps" {
  count                  = local.public_gw_eg_on_alb ? 1 : 0
  wait_for_load_balancer = true

  metadata {
    name      = "envoy-apps"
    namespace = kubernetes_namespace.envoy_gateway[0].id
    annotations = merge({
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/group.name"       = "apps-eg"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"

      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz"
      "alb.ingress.kubernetes.io/healthcheck-port"     = "traffic-port"

      "alb.ingress.kubernetes.io/certificate-arn"      = data.terraform_remote_state.certs.outputs.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\" } }"

      "alb.ingress.kubernetes.io/inbound-cidrs" = join(",", local.public_gw_eg_source_ranges)
      "alb.ingress.kubernetes.io/tags"          = join(",", local.envoy_apps_alb_tags_list)
    }, local.envoy_apps_waf_annotations)
  }

  spec {
    ingress_class_name = local.public_ingress_class

    # One rule per hostname rather than a single catch-all: externaldns-public
    # publishes what it finds in `host`, and the routes that carry the same
    # hostnames are hidden from it to avoid a double claim on the record.
    dynamic "rule" {
      for_each = toset(local.public_gw_eg_alb_hostnames)

      content {
        host = rule.value

        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = "ssl-redirect"
                port {
                  name = "use-annotation"
                }
              }
            }
          }

          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = local.public_gw_eg_svc_name
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.envoy_gateway.public_gateway.open_to_internet || length(var.envoy_gateway_public_allowed_cidrs) > 0
      error_message = "envoy_gateway_public_allowed_cidrs must not be empty while the public gateway is on the ALB frontend and `open_to_internet` is false: `inbound-cidrs` would be empty and the AWS Load Balancer Controller would leave the ALB's security group open to 0.0.0.0/0 anyway — as an accident rather than a decision. Either set the list in allowlist.local.auto.tfvars (see allowlist.local.auto.tfvars.example), or set `open_to_internet = true` to say the perimeter is open on purpose."
    }
  }

  depends_on = [
    helm_release.alb_ingress,
    kubernetes_manifest.public_gateway_eg,
    kubernetes_manifest.public_gw_eg_healthz_route,
    # Backs an ALB provisioned by the LBC, which is deleted asynchronously --
    # see the drain gate above.
    time_sleep.controller_drain,
  ]
}
