#===========================================#
# Transit Gateway Locals
# Additional computed values and merged data
# Remote state definitions are in runtime.tf
#===========================================#
locals {
  # Merged tags from metadata, compliance, and defaults
  tags = merge(
    {
      Terraform           = "true"
      Environment         = local.environment
      ProtectFromDeletion = "true"
      Layer               = local.layer_name
    },
    local.tags,
    local.compliance_tags
  )

  # Merged VPC data sources for reference
  datasources-vpcs = merge(
    data.terraform_remote_state.network-vpcs, # network
    #data.terraform_remote_state.shared-vpcs,  # shared
    data.terraform_remote_state.apps-devstg-vpcs, # apps-devstg-vpcs
    data.terraform_remote_state.apps-prd-vpcs,    # apps-prd-vpcs
  )
}
