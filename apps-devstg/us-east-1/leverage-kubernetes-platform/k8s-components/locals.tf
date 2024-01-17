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
    Cluster     = "eks-lkp"
    Terraform   = "true"
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
  public_ingress_class  = "public-apps"  # DemoApps
  private_ingress_class = "private-apps" # E.g. ArgoCD

  #------------------------------------------------------------------------------
  # Nginx Ingress settings
  #------------------------------------------------------------------------------
  nginx_ingress_tags_map = merge(local.tags_map, { Component = "nginx-ingress" })
  nginx_ingress_tags_list = [
    for k, v in local.alb_ingress_to_nginx_ingress_tags_map : "${k}=${v}"
  ]

  #------------------------------------------------------------------------------
  # ALB Ingress settings
  #------------------------------------------------------------------------------
  alb_ingress_to_nginx_ingress_tags_map = merge(local.tags_map, { Component = "alb-ingress" })
  alb_ingress_to_nginx_ingress_tags_list = [
    for k, v in local.alb_ingress_to_nginx_ingress_tags_map : "${k}=${v}"
  ]
  eks_alb_logging_prefix = var.eks_alb_logging_prefix != "" ? var.eks_alb_logging_prefix : data.terraform_remote_state.cluster.outputs.cluster_name

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
