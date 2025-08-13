#=============================#
# Debug Outputs               #
#=============================#

output "accounts_settings" {
  description = "Accounts settings with merged settings from settings.tfvars and dev_settings.tfvars"
  value       = local.accounts_settings
} 
