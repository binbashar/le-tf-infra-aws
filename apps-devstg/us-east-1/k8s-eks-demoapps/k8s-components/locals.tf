locals {
  #------------------------------------------------------------------------------
  # Common settings
  #------------------------------------------------------------------------------
  environment = replace(var.environment, "apps-", "")
  platform    = "demo.${local.environment}"
  labels = {
    environment                    = var.environment
    "app.kubernetes.io/managed-by" = "Terraform"
    "app.kubernetes.io/part-of"    = var.environment
  }
  tags_map = {
    Environment = local.environment
    Cluster     = "eks-demoapps"
    Terraform   = "true"
    Layer       = local.layer_name
  }
  tags_list = [
    for k, v in local.tags_map : "${k}=${v}"
  ]

  #------------------------------------------------------------------------------
  # DNS settings
  #------------------------------------------------------------------------------
  # Keep in mind we are using the following convention for our public and
  # private domains:
  #   - Public Domain: binbash.com.ar
  #   - Private Domain: aws.binbash.com.ar
  #
  public_base_domain  = data.terraform_remote_state.shared-dns.outputs.aws_public_zone_domain_name
  private_base_domain = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_domain_name
  # The following is used as an annotation filter for ExternalDNS. The only
  # purpose for this is to signal the public ExternalDNS to make changes to the
  # public zone. Refer to the "echo-server" to understand how it can be used.
  public_dns_type = "public"

  #------------------------------------------------------------------------------
  # Ingress settings
  #------------------------------------------------------------------------------
  # Ingress classes identify the different ingress controllers we have
  public_ingress_class = "public-apps" # DemoApps

  # DEAD CLASS — nothing serves it. `ingress_nginx_private` was the only
  # controller watching `private-apps` and it is disabled: private L7 traffic
  # now goes through Envoy Gateway (`private-gw-eg`) via HTTPRoutes, not
  # Ingresses. Traefik would claim the same class but is disabled too.
  #
  # Still referenced by the chart values of argocd (cicd-argo.tf),
  # kube-prometheus-stack (monitoring-metrics.tf) and uptime-kuma
  # (monitoring-other.tf), plus hardcoded as the literal `private-apps` in
  # chart-values/{gatus,goldilocks}.yaml. Every one of those components is
  # currently `enabled = false`, so nothing renders and nothing breaks — but
  # re-enabling any of them yields an Ingress no controller will ever pick up.
  # Whoever does that needs to give it an HTTPRoute against `private-gw-eg`
  # instead. Kept rather than deleted so those references still resolve and
  # this note stays attached to them.
  private_ingress_class = "private-apps"

  #------------------------------------------------------------------------------
  # Nginx Ingress settings
  #------------------------------------------------------------------------------
  nginx_ingress_tags_map = merge(local.tags_map, { Component = "nginx-ingress" })
  nginx_ingress_tags_list = [
    for k, v in local.nginx_ingress_tags_map : "${k}=${v}"
  ]

  #------------------------------------------------------------------------------
  # Traefik Ingress settings
  #------------------------------------------------------------------------------
  traefik_tags_map = merge(local.tags_map, { Component = "traefik" })
  traefik_tags_list = [
    for k, v in local.traefik_tags_map : "${k}=${v}"
  ]

  # Gateway API CRDs standard channel manifest (upstream GitHub release).
  # Shared by every Gateway API data plane — see networking-gateway-api.tf.
  gateway_api_crds_url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.envoy_gateway.gateway_api_version}/standard-install.yaml"

  #------------------------------------------------------------------------------
  # Envoy Gateway settings
  #------------------------------------------------------------------------------
  envoy_gateway_tags_map = merge(local.tags_map, { Component = "envoy-gateway" })
  envoy_gateway_tags_list = [
    for k, v in local.envoy_gateway_tags_map : "${k}=${v}"
  ]
  private_gw_eg_wildcard_cert_secret = "private-gw-eg-wildcard-tls"
  public_gw_eg_wildcard_cert_secret  = "public-gw-eg-wildcard-tls"

  # Namespaces may only attach HTTPRoutes to the public Gateway when they carry
  # this label. Unlike the private Gateway (which accepts routes from every
  # namespace, since reaching it already requires VPN), the public one is
  # opt-in: a workload can't put itself on the internet just by writing an
  # HTTPRoute — a cluster admin has to label its namespace first.
  public_gw_eg_exposure_label = {
    key   = "gateway.binbash.com.ar/public-exposure"
    value = "allowed"
  }

  #------------------------------------------------------------------------------
  # ALB Ingress settings
  #------------------------------------------------------------------------------
  alb_ingress_to_nginx_ingress_tags_map = merge(local.tags_map, { Component = "alb-ingress" })
  alb_ingress_to_nginx_ingress_tags_list = [
    for k, v in local.alb_ingress_to_nginx_ingress_tags_map : "${k}=${v}"
  ]
  eks_alb_logging_prefix = var.ingress.apps_ingress.logging.prefix != "" ? var.ingress.apps_ingress.logging.prefix : data.terraform_remote_state.cluster.outputs.cluster_name

  load_balancer_attributes = var.ingress.apps_ingress.logging.enabled ? "access_logs.s3.enabled=${var.ingress.apps_ingress.logging.enabled},access_logs.s3.bucket=${var.project}-${var.environment}-alb-logs,access_logs.s3.prefix=${local.eks_alb_logging_prefix}" : "access_logs.s3.enabled=${var.ingress.apps_ingress.logging.enabled}"

  #------------------------------------------------------------------------------
  # Argo Settings
  #------------------------------------------------------------------------------
  argocd_slack_notifications_channel = "le-tools-monitoring"

  #------------------------------------------------------------------------------
  # Tools Node Group: Selectors and Tolerations
  #------------------------------------------------------------------------------
  tools_nodeSelector = jsonencode({ stack = "tools" })
  tools_tolerations = jsonencode([
    {
      key      = "stack",
      operator = "Equal",
      value    = "tools",
      effect   = "NoSchedule"
    }
  ])
}
