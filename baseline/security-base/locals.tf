
locals {
  account_name = var.account_name
  
  # Transform accounts variable into accounts_settings structure
  accounts_settings = {
    for region in var.accounts[local.account_name].regions : region => {
      environment = local.account_name
      parameters = try(var.parameters[local.account_name], var.parameters["default"])

    }
  }
}
  
  