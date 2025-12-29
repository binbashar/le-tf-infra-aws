#===========================================#
# VPC Endpoints Module
# Maps endpoints_config design spec to terraform-aws-modules/vpc/aws//modules/vpc-endpoints
# All computed values (locals) are defined in runtime.tf
#===========================================#
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = var.endpoints_config.version

  # Core Configuration
  create = local.default_create
  region = var.endpoints_config.region
  vpc_id = local.vpc_id

  # Endpoints Configuration (passed directly, no transformation needed)
  endpoints = var.endpoints_config.networking.endpoints

  # Default Network Configuration
  security_group_ids = local.default_security_group_ids
  subnet_ids         = local.default_subnet_ids
  tags               = local.default_tags
  timeouts           = local.default_timeouts

  # Security Group Configuration
  create_security_group      = local.security_group_create
  security_group_name        = local.security_group_name
  security_group_name_prefix = local.security_group_name_prefix
  security_group_description = local.security_group_description
  security_group_rules       = local.security_group_rules
  security_group_tags        = local.security_group_tags
}
