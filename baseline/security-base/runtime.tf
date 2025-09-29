
locals {

  # Merge var.accounts with runtime overrides
  # Runtime values will override the variable values, but keep all other parameters
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

  # Merge var.accounts with runtime overrides
  accounts = merge(
    var.accounts,
    {
      management = merge(
        var.accounts.management,
        local.runtime_accounts.management
      )
      security = merge(
        var.accounts.security,
        local.runtime_accounts.security
      )
      shared = merge(
        var.accounts.shared,
        local.runtime_accounts.shared
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

  # Transform accounts variable into accounts_settings structure
  account_settings = merge([
    for account, config in local.accounts : {
      for region in lookup(config, "regions", []) :
      "${account}-${region}" => {
        region = region
        id = lookup(config, "id", null)
        email = lookup(config, "email", null)
        profile = lookup(config, "profile", null)
        inputs = try(var.inputs[account], var.inputs["default"])
      }
    }
  ]...) 
}
  
  
