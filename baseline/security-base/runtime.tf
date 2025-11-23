
locals {

  # ================================================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNT PROVIDER OVERRIDES
  # -----------------------------------------------------------
  # Purpose: Define per-account runtime settings used to build
  # provider aliases and resource matrices (one per region).
  # Notes:
  # - Profiles map to SSO/credential profiles.
  # - Regions come from variables (primary/secondary) to keep
  #   the account footprint consistent across the layer.
  # ================================================================
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

  # ================================================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNTS MERGE (BASE + OVERRIDES)
  # -----------------------------------------------------------
  # Purpose: Combine the base account configuration (var.accounts)
  # with the injected runtime overrides above. This preserves any
  # fields not set at runtime while ensuring profiles/regions are enforced.
  # Result: local.accounts is the single source of truth for the
  # rest of this module (providers and resources).
  # ================================================================
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

  # ================================================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNT SETTINGS MATRIX (ACCOUNT x REGION)
  # -----------------------------------------------------------
  # Purpose: Expand accounts into a flat map keyed by
  # "{account}-{region}" to drive for_each on resources.
  # Details:
  # - Pulls region/profile/id/email from the merged accounts.
  # - inputs selects per-account settings from var.inputs,
  #   falling back to the "default" key when not defined.
  # Usage: Consumed by resources (e.g., EBS encryption, S3 public
  # access block) and matching provider aliases via the same key.
  # Transform accounts variable into accounts_settings structure
  # ================================================================
  account_settings = merge([
    for account, config in local.accounts : {
      for region in lookup(config, "regions", []) :
      "${account}-${region}" => {
        region = region
        email = lookup(config, "email", null)
        profile = lookup(config, "profile", null)
        inputs = try(var.inputs[account], var.inputs["default"])
      }
    }
  ]...) 
}
  
  