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
# Gateways, the nginx/traefik controllers) gets the `service.k8s.aws/resources`
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
# Nginx Ingress (Private): Route inside traffic to services in the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx_private" {
  count      = var.ingress.nginx_controller.enabled && !var.ingress.traefik.enabled ? 1 : 0
  name       = "ingress-nginx-private"
  namespace  = kubernetes_namespace.ingress_nginx[0].id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.14.3"
  values = [
    templatefile("chart-values/ingress-nginx.yaml", {
      ingressClass = local.private_ingress_class,
      tags         = join(",", local.nginx_ingress_tags_list)
    })
  ]

  # Owns a Service of type LoadBalancer, so it must be torn down before the LBC
  # -- see the drain gate above.
  depends_on = [
    time_sleep.controller_drain,
  ]
}

#------------------------------------------------------------------------------
# Traefik (Private): Route inside traffic to services in the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "traefik" {
  count      = !var.ingress.nginx_controller.enabled && var.ingress.traefik.enabled ? 1 : 0
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
# Apps Ingress ALB2Nginx
# -----------------------------------------------------------------------------
# This ingress object defines the attributes of an Application Load Balancer
# (ALB) which will be created by the ALB Ingress Controller. Such LB will serve
# as an entrypoint for traffic that needs to reach any services hosted in the
# cluster.
# When using an internet-facing ALB, the traffic flow will work as follows:
#
#   Internet => ALB => Nginx Ingress (pods) => App (service)
#
# There is also the option to use an internal ALB, in which case the traffic
# will work like this:
#
#   VPN => ALB => Nginx Ingress (pods) => App (service)
#
#------------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "nginx_apps" {
  count                  = var.ingress.apps_ingress.enabled && var.ingress.alb_controller.enabled && var.ingress.nginx_controller.enabled && !var.ingress.traefik.enabled ? 1 : 0
  wait_for_load_balancer = true

  metadata {
    name      = "apps"
    namespace = kubernetes_namespace.ingress_nginx[0].id
    annotations = {
      # This is used by the ALB Ingress
      # This annotation is deprecated in newer K8s versions as per https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation
      # Use spec.ingressClassName (ingress_class_name) instead
      # "kubernetes.io/ingress.class" = "${local.public_ingress_class}"
      # Load balancer type: internet-facing or internal
      "alb.ingress.kubernetes.io/scheme" = var.ingress.apps_ingress.type
      # Group this LB under a custom group so it's not shared with other groups
      "alb.ingress.kubernetes.io/group.name" = "apps"
      # Nginx provides an endpoint for health checks
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
      # Use the AWS ACM certificate we created for this
      "alb.ingress.kubernetes.io/certificate-arn" = data.terraform_remote_state.certs.outputs.certificate_arn
      # Enable ports 80 and 443
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      # Define the SSL Redirect action
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\" } }"
      # Use HTTPS as we are forwarding to the https port of the nginx-ingress service
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      # Define resource tags
      "alb.ingress.kubernetes.io/tags" = join(",", local.alb_ingress_to_nginx_ingress_tags_list)
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
              name = "ingress-nginx-private-controller"
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
    helm_release.ingress_nginx_private,
    # Backs an ALB provisioned by the LBC, which is likewise deleted
    # asynchronously -- see the drain gate above.
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
  count                  = var.ingress.apps_ingress.enabled && var.ingress.alb_controller.enabled && !var.ingress.nginx_controller.enabled && var.ingress.traefik.enabled ? 1 : 0
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
      # Nginx provides an endpoint for health checks
      "alb.ingress.kubernetes.io/healthcheck-path" = "/ping"
      # Use the AWS ACM certificate we created for this
      "alb.ingress.kubernetes.io/certificate-arn" = data.terraform_remote_state.certs.outputs.certificate_arn
      # Enable ports 80 and 443
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      # Define the SSL Redirect action
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\" } }"
      # Use HTTPS as we are forwarding to the https port of the nginx-ingress service
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      # Define resource tags
      "alb.ingress.kubernetes.io/tags" = join(",", local.alb_ingress_to_nginx_ingress_tags_list)
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
