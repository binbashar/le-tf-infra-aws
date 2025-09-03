
locals {

  # Merge var.accounts with runtime overrides
  # Runtime values will override the variable values, but keep all other parameters
  runtime_accounts = {
    root = {
      profile = "bb-root-devops"
      regions = [
        "us-east-1",
        "us-west-2",
        "us-east-2"
      ]
    }
    security = {
      profile = "bb-security-devops"
      regions = [
        "us-east-1",
        "us-west-2",
      ]
    },
    shared = {
      profile = "bb-shared-devops"
      regions = [
        "us-east-1",
        "us-west-2",
      ]
    },
    network = {
      profile = "bb-network-devops"
      regions = [
        "us-east-1",
        "us-west-2",
      ]
    },
    apps-devstg = {
      profile = "bb-apps-devstg-devops"
      regions = [
        "us-east-1",
        "us-west-2",
      ]
    },
    apps-prd = {
      profile = "bb-apps-prd-devops"
      regions = [
        "us-east-1",
        "us-west-2",
      ]
    },
    data-science = {
      profile = "bb-data-science-devops"
      regions = [
        "us-east-1",
        "us-west-2",
      ]
    }
  }

  # Merge var.accounts with runtime overrides
  accounts = merge(
    var.accounts,
    {
      root = merge(
        var.accounts.root,
        local.runtime_accounts.root
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
  
  