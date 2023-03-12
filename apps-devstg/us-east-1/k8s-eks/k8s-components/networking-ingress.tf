#------------------------------------------------------------------------------
# AWS Load Balancer (Ingress) Controller: Route outside traffic to the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "alb_ingress" {
  count      = var.enable_alb_ingress_controller ? 1 : 0
  name       = "alb-ingress"
  namespace  = kubernetes_namespace.alb_ingress[0].id
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.2"
  values = [
    templatefile("chart-values/alb-ingress.yaml", {
      clusterName        = data.terraform_remote_state.eks-cluster.outputs.cluster_name,
      ingressClass       = local.public_ingress_class,
      serviceAccountName = "alb-ingress",
      roleArn            = data.terraform_remote_state.eks-identities.outputs.aws_lb_controller_role_arn,
    })
  ]
}

#------------------------------------------------------------------------------
# Nginx Ingress (Private): Route inside traffic to services in the cluster.
#------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx_private" {
  count      = var.enable_nginx_ingress_controller ? 1 : 0
  name       = "ingress-nginx-private"
  namespace  = kubernetes_namespace.ingress_nginx[0].id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.1.1"
  values = [
    templatefile("chart-values/ingress-nginx.yaml", {
      ingressClass = local.private_ingress_class,
      tags         = join(",", local.tags_list),
    })
  ]
}

#------------------------------------------------------------------------------
# Apps Ingress
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
resource "kubernetes_ingress_v1" "apps" {
  count                  = var.apps_ingress.enabled ? 1 : 0
  wait_for_load_balancer = true

  metadata {
    name      = "apps"
    namespace = kubernetes_namespace.ingress_nginx[0].id
    annotations = {
      # This is used by the ALB Ingress
      "kubernetes.io/ingress.class" = "${local.public_ingress_class}"
      # Load balancer type: internet-facing or internal
      "alb.ingress.kubernetes.io/scheme" = var.apps_ingress.type
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
      alb.ingress.kubernetes.io/load-balancer-attributes = "access_logs.s3.enabled=${var.eks_alb_logging},access_logs.s3.bucket=${var.project}-${var.environment}-alb-logs,access_logs.s3.prefix=eks-cluster-ingress"
    }
  }

  spec {
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
    helm_release.ingress_nginx_private
  ]
}
