locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # Runtime backend settings - only specific parameters to override
  runtime_accounts = {
    management = {
      profile = "bb-management-administrator"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
    shared = {
      profile = "bb-shared-devops"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
    security = {
      profile = "bb-security-devops"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
    network = {
      profile = "bb-network-devops"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
    apps-devstg = {
      profile = "bb-apps-devstg-devops"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
    apps-prd = {
      profile = "bb-apps-prd-devops"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
    data-science = {
      profile = "bb-data-science-devops"
      regions = [
        var.region_primary,
        var.region_secondary
      ]
    }
  }
  runtime_backend_settings = {
    bucket = {
    }
    security = {
    }
    replication = {
    }
    tags = {
      Layer = "baseline"
    }
  }

  # Merge var.accounts with runtime overrides
  # Runtime values will override the variable values, but keep all other parameters
  accounts = merge(
    var.accounts,
    {
      management = merge(
        var.accounts.management,
        local.runtime_accounts.management
      )
      shared = merge(
        var.accounts.shared,
        local.runtime_accounts.shared
      )
      security = merge(
        var.accounts.security,
        local.runtime_accounts.security
      )
      network = merge(
        var.accounts.network,
        local.runtime_accounts.network
      )
      apps-devstg = merge(
        var.accounts.apps-devstg,
        local.runtime_accounts.apps-devstg
      )
      apps-prd = merge(
        var.accounts.apps-prd,
        local.runtime_accounts.apps-prd
      )
      data-science = merge(
        var.accounts.data-science,
        local.runtime_accounts.data-science
      )
    }
  )

  # Transform accounts variable into accounts_providers structure
  accounts_providers = merge([
    for account, config in local.accounts : {
      for region in lookup(config, "regions", []) :
      "${account}-${region}" => {
        region  = region
        id      = lookup(config, "id", null)
        email   = lookup(config, "email", null)
        profile = lookup(config, "profile", null)
      }
    }
  ]...)

  # Transform accounts variable into accounts_resources structure
  accounts_resources = merge([
    for account, config in local.accounts : {
      "${account}" : {
        id               = lookup(config, "id", null)
        email            = lookup(config, "email", null)
        region_primary   = config.regions[0]
        region_secondary = config.regions[1]
        inputs           = local.backend_settings
      }
    }
  ]...)

  # Merge var.backend_settings with runtime overrides
  # Runtime values will override the variable values, but keep all other parameters
  backend_settings = merge(
    var.backend_settings,
    {
      bucket = merge(
        var.backend_settings.bucket,
        local.runtime_backend_settings.bucket
      )
      security = merge(
        var.backend_settings.security,
        local.runtime_backend_settings.security
      )
      replication = merge(
        var.backend_settings.replication,
        local.runtime_backend_settings.replication
      )
      tags = merge(
        var.backend_settings.tags,
        local.runtime_backend_settings.tags
      )
    }
  )
}
