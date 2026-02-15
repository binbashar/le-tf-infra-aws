locals {
  # ===========================================
  # STANDARD TAGS FOR ALL RESOURCES IN THIS LAYER
  # -------------------------------------------
  # Purpose: Provide a consistent tagging baseline across resources
  # created by this module. These are merged with per-resource tags
  # when applicable.
  # ===========================================
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  # ===========================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNT OVERRIDES
  # -------------------------------------------
  # Purpose: Define per-account runtime settings (profiles/regions)
  # to build provider aliases and resource matrices.
  # Notes:
  # - Profiles map to SSO/credential profiles in the runner.
  # - Regions rely on primary/secondary variables for consistency.
  # Runtime backend settings - only specific parameters to override
  # ===========================================
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
  # RUNTIME DEPENDENCY INJECTION: BACKEND SETTINGS OVERRIDES
  # -----------------------------------------------------------
  # Purpose: Minimal, targeted overrides for backend settings that
  # should differ at runtime without redefining the full structure.
  # ================================================================
  runtime_backend_settings = {
    bucket = {
    }
    security = {
    }
    replication = {
    }
    tags = {
      Layer = "base-tf-backend"
    }
  }

  # ================================================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNTS MERGE (BASE + OVERRIDES)
  # -----------------------------------------------------------
  # Purpose: Combine base account definitions with the runtime
  # overrides above. Unspecified fields remain from base config.
  # Result: local.accounts is the canonical structure downstream.
  # ================================================================
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

  # ================================================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNTS → PROVIDERS MATRIX
  # -----------------------------------------------------------
  # Purpose: Expand accounts into a map keyed by "account-region"
  # used to instantiate provider aliases per account/region.
  # Includes id/email/profile to support auditing and provider auth.
  # Transform accounts variable into accounts_providers structure
  # ================================================================
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

  # ================================================================
  # RUNTIME DEPENDENCY INJECTION: AWS ACCOUNTS → RESOURCES INPUT MAP
  # -----------------------------------------------------------
  # Purpose: Create a simplified per-account map consumed by the
  # tfstate-backend module. It carries account metadata, primary/
  # secondary regions, and the merged backend settings.
  # Transform accounts variable into accounts_resources structure
  # ================================================================
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

  # ===========================================
  # RUNTIME DEPENDENCY INJECTION: BACKEND SETTINGS MERGE (BASE + OVERRIDES)
  # -------------------------------------------
  # Purpose: Layer runtime overrides over base backend settings,
  # preserving unspecified values. This feeds downstream modules.
  # ===========================================
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
