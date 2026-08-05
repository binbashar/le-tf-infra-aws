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

  # DEAD CLASS — nothing serves it, and as of the HTTPRoute conversion nothing
  # consumes it either. `ingress_nginx_private` was the only controller
  # watching `private-apps` and it is disabled; traefik would claim the same
  # class and is disabled too. Private L7 traffic goes through Envoy Gateway
  # (`private-gw-eg`) via HTTPRoutes — see networking-httproutes.tf for the
  # full list of what is published and on which hostname.
  #
  # The only two references left are the nginx and traefik chart values in
  # networking-ingress.tf, i.e. the controllers that would *serve* the class
  # rather than anything that would *use* it. That is the right place for the
  # name to live. Every former consumer — argocd, argo-rollouts,
  # kube-prometheus-stack (×3 hostnames), uptime-kuma, gatus and goldilocks —
  # now has a row in the route table instead.
  #
  # Kept rather than deleted because re-enabling either controller still needs
  # a class name, and because this note is the explanation for why an Ingress
  # written against `private-apps` would silently never be picked up.
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

  # Gateway API CRDs standard channel manifest, vendored under crds/.
  # Shared by every Gateway API data plane — see networking-gateway-api.tf.
  # The filename carries the version so a bump of `gateway_api_version` that
  # forgets to re-vendor fails loudly on a missing file instead of silently
  # applying the old CRDs against a new chart.
  gateway_api_crds_path = "${path.module}/crds/gateway-api-standard-${var.envoy_gateway.gateway_api_version}.yaml"

  #------------------------------------------------------------------------------
  # Envoy Gateway settings
  #------------------------------------------------------------------------------
  envoy_gateway_tags_map = merge(local.tags_map, { Component = "envoy-gateway" })
  envoy_gateway_tags_list = [
    for k, v in local.envoy_gateway_tags_map : "${k}=${v}"
  ]
  private_gw_eg_wildcard_cert_secret = "private-gw-eg-wildcard-tls"
  public_gw_eg_wildcard_cert_secret  = "public-gw-eg-wildcard-tls"

  #----------------------------------------------------------------------------
  # Shared by every private HTTPRoute. Each route lives next to the
  # `helm_release` it exposes — argocd's in cicd-argo.tf, grafana's in
  # monitoring-metrics.tf, and so on — so that turning a component on or off is
  # one file, not two. These two locals are the only part worth factoring out.
  #
  # Conventions those routes all follow, all of them load-bearing:
  #
  #   - **Hostname is one label below the private base domain**, i.e.
  #     `<app>.aws.binbash.com.ar`. That is what the wildcard cert bound to the
  #     gateway's HTTPS listener covers. The older
  #     `<app>.demo.devstg.aws.binbash.com.ar` scheme sat three labels down and
  #     a single-label wildcard does not match it, so every component would
  #     have needed a certificate of its own. Flattening is what lets one
  #     shared cert serve all of them.
  #   - **No TLS block, no cert-manager annotation.** The gateway terminates.
  #   - **No HTTP variant.** `private-gw-eg`'s port-80 listener only accepts
  #     routes from its own namespace, and the redirector living there sends
  #     everything to HTTPS — so attaching here is HTTPS-only by construction.
  #   - **Plain HTTP upstream.** Every backend serves cleartext inside the
  #     cluster. The one that did not, argocd-server, was told to stop
  #     (`server.insecure`) rather than have the gateway re-encrypt.
  #
  # external-dns watches `gateway-httproute`, so the Route53 record follows
  # from the `hostnames` field with no extra annotation, and deleting a route
  # deletes the record on the next reconcile (policy `sync`).
  #----------------------------------------------------------------------------
  private_gw_enabled = var.envoy_gateway.enabled && var.envoy_gateway.private_gateway.enabled

  # Cross-namespace parentRef. No ReferenceGrant needed: the gateway's HTTPS
  # listener sets `allowedRoutes.namespaces.from = All`, and grants are only
  # required for cross-namespace *backendRefs* — every route here resolves a
  # Service in its own namespace.
  private_gw_parent_refs = [{
    name      = "private-gw-eg"
    namespace = "envoy-gateway-system"
  }]

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

  # One label below the private base domain, so the `*.aws.binbash.com.ar`
  # wildcard bound to `private-gw-eg`'s HTTPS listener covers it. The old
  # `argocd.${local.platform}.${local.private_base_domain}` form sat three
  # labels down and would have needed a certificate of its own.
  argocd_host = "argocd.${local.private_base_domain}"

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
