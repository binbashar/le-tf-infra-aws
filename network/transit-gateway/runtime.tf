#===========================================#
# Transit Gateway Configuration Locals
# Computed values derived from tgw_config design spec
#===========================================#
locals {
  # Metadata values
  tgw_name         = var.tgw_config.metadata.name
  environment      = var.tgw_config.metadata.environment
  region           = var.tgw_config.region
  region_secondary = try(var.tgw_config.region_secondary, null)
  tags             = var.tgw_config.metadata.tags

  # Extract project name from metadata.name (format: project-environment-tgw)
  # Fallback to var.project if provided for backward compatibility
  project = try(var.project, split("-", var.tgw_config.metadata.name)[0])

  # Connection values
  create_tgw         = try(var.tgw_config.connection.create, true)
  existing_tgw_id    = try(var.tgw_config.connection.existing_tgw_id, null)
  enable_network     = try(var.tgw_config.connection.accounts.network, false)
  enable_shared      = try(var.tgw_config.connection.accounts.shared, false)
  enable_apps_devstg = try(var.tgw_config.connection.accounts.apps-devstg, false)
  enable_apps_prd    = try(var.tgw_config.connection.accounts.apps-prd, false)

  # Legacy variable mapping (for backward compatibility)
  enable_tgw = try(var.enable_tgw, local.create_tgw)
  enable_vpc_attach = {
    network     = local.enable_network
    shared      = local.enable_shared
    apps-devstg = local.enable_apps_devstg
    apps-prd    = local.enable_apps_prd
  }

  # Networking values
  create_default_route_table     = try(var.tgw_config.networking.route_tables.default.create, true)
  create_inspection_route_table  = try(var.tgw_config.networking.route_tables.inspection.create, false)
  create_apps_devstg_route_table = try(var.tgw_config.networking.route_tables.apps-devstg.create, false)
  create_apps_prd_route_table    = try(var.tgw_config.networking.route_tables.apps-prd.create, false)
  blackhole_routes               = try(var.tgw_config.networking.blackhole_routes, [])

  # Legacy blackhole routes mapping
  tgw_cidrs = try(var.tgw_cidrs, {
    for cidr in local.blackhole_routes : cidr => cidr
  })

  # Security values
  ram_sharing_enabled      = try(var.tgw_config.security.ram_sharing.enabled, true)
  ram_sharing_principals   = try(var.tgw_config.security.ram_sharing.principals, [])
  network_firewall_enabled = try(var.tgw_config.security.network_firewall.enabled, false)

  # Legacy variable mapping (for backward compatibility)
  # Note: var.enable_network_firewall is defined as a legacy variable in variables.tf
  enable_network_firewall = try(var.enable_network_firewall, local.network_firewall_enabled)

  # High availability values
  multi_region_enabled = try(var.tgw_config.high_availability.multi_region.enabled, false)
  peer_region          = try(var.tgw_config.high_availability.multi_region.peer_region, null)

  # Legacy variable mapping
  enable_tgw_multi_region = try(var.enable_tgw_multi_region, local.multi_region_enabled)

  # Monitoring values
  monitoring_enabled = try(var.tgw_config.monitoring.enabled, false)

  # Logging values
  logging_enabled = try(var.tgw_config.logging.enabled, false)

  # Compliance values
  compliance_tags = try(var.tgw_config.compliance.tags, {})

  # Automation values
  auto_accept_attachments = try(var.tgw_config.automation.auto_accept_attachments, false)
  auto_propagate_routes   = try(var.tgw_config.automation.auto_propagate_routes, false)

  # Remote state data source definitions (from locals.tf)
  # These are kept for backward compatibility with existing remote state lookups
  shared-vpcs = {
    shared-base = {
      region  = local.region
      profile = "${local.project}-shared-devops"
      bucket  = "${local.project}-shared-terraform-backend"
      key     = "shared/network/terraform.tfstate"
    }
  }

  network-vpcs = {
    network-base = {
      region  = local.region
      profile = "${local.project}-network-devops"
      bucket  = "${local.project}-network-terraform-backend"
      key     = "network/network/terraform.tfstate"
    }
  }

  apps-devstg-vpcs = {
    apps-devstg-base = {
      region  = local.region
      profile = "${local.project}-apps-devstg-devops"
      bucket  = "${local.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/network/terraform.tfstate"
    }
    apps-devstg-k8s-eks = {
      region  = local.region
      profile = "${local.project}-apps-devstg-devops"
      bucket  = "${local.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks/network/terraform.tfstate"
    }
    apps-devstg-eks-demoapps = {
      region  = local.region
      profile = "${local.project}-apps-devstg-devops"
      bucket  = "${local.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-demoapps/network/terraform.tfstate"
    }
  }

  apps-prd-vpcs = {
    apps-prd-base = {
      region  = local.region
      profile = "${local.project}-apps-prd-devops"
      bucket  = "${local.project}-apps-prd-terraform-backend"
      key     = "apps-prd/network/terraform.tfstate"
    }
  }

  # Secondary region
  shared-dr-vpcs = {
    shared-base-dr = {
      region  = local.region
      profile = "${local.project}-shared-devops"
      bucket  = "${local.project}-shared-terraform-backend"
      key     = "shared/network-dr/terraform.tfstate"
    }
  }

  network-dr-vpcs = {
    network-base-dr = {
      region  = local.region
      profile = "${local.project}-network-devops"
      bucket  = "${local.project}-network-terraform-backend"
      key     = "network/network-dr/terraform.tfstate"
    }
  }

  apps-devstg-dr-vpcs = {
    apps-devstg-k8s-eks-dr = {
      region  = local.region
      profile = "${local.project}-apps-devstg-devops"
      bucket  = "${local.project}-apps-devstg-terraform-backend"
      key     = "apps-devstg/k8s-eks-dr/network/terraform.tfstate"
    }
  }

  apps-prd-dr-vpcs = {}

  # Layer name for tags
  layer_name = "transit-gateway"
}

