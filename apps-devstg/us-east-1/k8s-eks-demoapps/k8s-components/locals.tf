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
  # consumes it either. traefik is the only controller left that would claim
  # `private-apps`, and it is disabled. Private L7 traffic goes through Envoy
  # Gateway (`private-gw-eg`) via HTTPRoutes. Each component publishes its own:
  # through its chart's native route key where the chart has one, and through a
  # `kubernetes_manifest` next to its `helm_release` where it does not
  # (uptime-kuma).
  #
  # The only reference left is the traefik chart values in
  # networking-ingress.tf, i.e. the controller that would *serve* the class
  # rather than anything that would *use* it. That is the right place for the
  # name to live. Every former consumer — argocd, argo-rollouts,
  # kube-prometheus-stack (×3 hostnames), uptime-kuma, gatus and goldilocks —
  # now has a row in the route table instead.
  #
  # Kept rather than deleted because re-enabling traefik still needs a class
  # name, and because this note is the explanation for why an Ingress written
  # against `private-apps` would silently never be picked up.
  private_ingress_class = "private-apps"

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

  # Which load balancer fronts the public gateway — see the `frontend` field on
  # `var.envoy_gateway.public_gateway`. Split out because a dozen `count` and
  # conditional expressions read it, and the two are mutually exclusive.
  public_gw_eg_enabled  = var.envoy_gateway.enabled && var.envoy_gateway.public_gateway.enabled
  public_gw_eg_on_alb   = local.public_gw_eg_enabled && var.envoy_gateway.public_gateway.frontend == "alb"
  public_gw_eg_on_nlb   = local.public_gw_eg_enabled && var.envoy_gateway.public_gateway.frontend == "nlb"
  public_gw_eg_svc_name = "public-gw-eg-envoy"

  # What the public frontend admits. `0.0.0.0/0` only when someone asked for it
  # through `open_to_internet` — an empty allowlist is treated as a mistake, not
  # as consent, and is caught by a precondition instead.
  public_gw_eg_source_ranges = var.envoy_gateway.public_gateway.open_to_internet ? ["0.0.0.0/0"] : var.envoy_gateway_public_allowed_cidrs

  #------------------------------------------------------------------------------
  # ALB Ingress settings
  #------------------------------------------------------------------------------
  # Tags for the ALB that fronts the private-class ingress controller. Named for
  # the role rather than the controller since nginx-ingress was removed and
  # traefik inherited it.
  alb_ingress_to_private_ingress_tags_map = merge(local.tags_map, { Component = "alb-ingress" })
  alb_ingress_to_private_ingress_tags_list = [
    for k, v in local.alb_ingress_to_private_ingress_tags_map : "${k}=${v}"
  ]

  envoy_apps_alb_tags_map = merge(local.tags_map, { Component = "alb-envoy-gateway" })
  envoy_apps_alb_tags_list = [
    for k, v in local.envoy_apps_alb_tags_map : "${k}=${v}"
  ]

  # The WAF association, as an annotation fragment merged into the Ingress
  # rather than a `wafv2_web_acl_association` resource.
  #
  # The Load Balancer Controller owns this ALB: its ARN does not exist when
  # either this layer or the firewall layer plans, and it is a different ARN
  # after every cluster re-spin. Handing the controller the WebACL ARN and
  # letting it make the association is the only form that survives that — and it
  # is also what the setup being modelled does, where the WAF is attached by an
  # annotation on each Ingress.
  #
  # The annotation is always present, empty when off -- NOT omitted. Verified
  # the hard way: removing the annotation leaves the WebACL associated. The
  # controller reads an absent `wafv2-acl-arn` as "no opinion, not mine to
  # manage" and never touches the existing association, so `waf_enabled = false`
  # with the key omitted silently left the WAF in the request path. An empty
  # value is what it reads as an explicit request to disassociate.
  #
  # This is the opposite of the `{}`-serialises-as-`null` trap on the EG CRDs,
  # where the fix *is* to omit the key. Ingress annotations are a plain string
  # map with no schema, and here the empty string is a meaningful value rather
  # than an absent one.
  envoy_apps_waf_annotations = {
    "alb.ingress.kubernetes.io/wafv2-acl-arn" = var.envoy_gateway.public_gateway.waf_enabled ? data.terraform_remote_state.firewall[0].outputs.wafv2_regional_alb_arn : ""
  }

  # Hostnames the ALB frontend serves and publishes.
  #
  # They have to be named here rather than discovered: externaldns-public reads
  # the Ingress, and an Ingress with no `host` gives it nothing to publish,
  # while the HTTPRoutes that do carry hostnames are hidden from it precisely
  # so the two do not both claim the same record.
  #
  # The duplication with k8s-workloads is a known rough edge of this shape --
  # adding a public app means editing this list as well as its HTTPRoute. It is
  # tolerable while there is one. The way out, if this grows, is to let each
  # HTTPRoute publish its own record with
  # `external-dns.alpha.kubernetes.io/target` pinned to the ALB.
  public_gw_eg_alb_hostnames = ["echo-server.${local.public_base_domain}"]
  eks_alb_logging_prefix     = var.ingress.apps_ingress.logging.prefix != "" ? var.ingress.apps_ingress.logging.prefix : data.terraform_remote_state.cluster.outputs.cluster_name

  load_balancer_attributes = var.ingress.apps_ingress.logging.enabled ? "access_logs.s3.enabled=${var.ingress.apps_ingress.logging.enabled},access_logs.s3.bucket=${var.project}-${var.environment}-alb-logs,access_logs.s3.prefix=${local.eks_alb_logging_prefix}" : "access_logs.s3.enabled=${var.ingress.apps_ingress.logging.enabled}"

  #------------------------------------------------------------------------------
  # Argo Settings
  #------------------------------------------------------------------------------
  argocd_slack_notifications_channel = "le-tools-monitoring"

  # One label below the private base domain, so the `*.aws.binbash.com.ar`
  # wildcard bound to `private-gw-eg`'s HTTPS listener covers it. The old
  # `argocd.${local.platform}.${local.private_base_domain}` form sat three
  # labels down and would have needed a certificate of its own.
  #------------------------------------------------------------------------------
  # ACME endpoint. Production unless `certmanager.acme_staging` says otherwise.
  #
  # The reason to have the switch: Let's Encrypt allows 5 duplicate
  # certificates per week for an identical set of identifiers, and this cluster
  # asks for two fixed sets — `aws.binbash.com.ar` + `*.aws.binbash.com.ar` and
  # `*.binbash.com.ar`. The second one is the corporate wildcard, so exhausting
  # its quota is felt outside this layer. A rehearsal that will be torn down
  # and rebuilt several times in a week belongs on staging, whose limits are
  # far looser and whose certificates are untrusted by design.
  #
  # It is a fallback, not the primary defence: preserving the issued Secrets
  # across a teardown costs nothing and re-issues nothing — see "Certificates"
  # in PLATFORM-NOTES.md. Use this when the Secrets are gone, or when the
  # issuance path itself is what is being rehearsed.
  #
  # The account key is per environment on purpose. An ACME account key is
  # registered with one directory; pointing the same key at the other server
  # makes cert-manager register a second account with it, which works but
  # leaves one Secret holding an identity on two servers.
  #------------------------------------------------------------------------------
  acme_staging     = try(var.certmanager.acme_staging, false)
  acme_server      = local.acme_staging ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
  acme_account_key = "${local.shared_clusterissuer_name}-account-key${local.acme_staging ? "-staging" : ""}"

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
