module "redshift" {
  source = "github.com/binbashar/terraform-aws-redshift?ref=v6.0.0"
  cluster_identifier    = local.name
  allow_version_upgrade = true
  node_type             = "ra3.large"
  number_of_nodes       = 1

  database_name   = "demo"
  master_username = "admin"
  # Either provide a good master password
  #  create_random_password = false
  #  master_password        = "MySecretPassw0rd1!" # Do better!
  # Or make Redshift manage it in secrets manager
  manage_master_password = true

  manage_master_password_rotation = false


  encrypted   = true
  kms_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  enhanced_vpc_routing   = true
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_ids             = data.terraform_remote_state.vpc.outputs.private_subnets

  # Only available when using the ra3.x type
  availability_zone_relocation_enabled = true

  iam_role_arns = [ aws_iam_role.redshift_role.arn ]

#   snapshot_copy = {
#     destination_region = "us-east-1"
#     grant_name         = aws_redshift_snapshot_copy_grant.useast1.snapshot_copy_grant_name
#   }

#   logging = {
#     bucket_name   = module.s3_logs.s3_bucket_id
#     s3_key_prefix = local.s3_prefix
#   }

  # Parameter group
#   parameter_group_name        = "${local.name}-custom"
#   parameter_group_description = "Custom parameter group for ${local.name} cluster"
#   parameter_group_parameters = {
#     wlm_json_configuration = {
#       name = "wlm_json_configuration"
#       value = jsonencode([
#         {
#           query_concurrency = 15
#         }
#       ])
#     }
#     require_ssl = {
#       name  = "require_ssl"
#       value = true
#     }
#     use_fips_ssl = {
#       name  = "use_fips_ssl"
#       value = false
#     }
#     enable_user_activity_logging = {
#       name  = "enable_user_activity_logging"
#       value = true
#     }
#     max_concurrency_scaling_clusters = {
#       name  = "max_concurrency_scaling_clusters"
#       value = 3
#     }
#     enable_case_sensitive_identifier = {
#       name  = "enable_case_sensitive_identifier"
#       value = true
#     }
#   }
#   parameter_group_tags = {
#     Additional = "CustomParameterGroup"
#   }

  # Subnet group
  subnet_group_name        = "${local.name}-subnet-group"
  subnet_group_description = "Custom subnet group for ${local.name} cluster"
#   subnet_group_tags = {
#     Additional = "CustomSubnetGroup"
#   }

  # Snapshot schedule
  create_snapshot_schedule        = false
  # snapshot_schedule_identifier    = local.name
  # use_snapshot_identifier_prefix  = true
  #snapshot_schedule_description   = "Example snapshot schedule"
#   snapshot_schedule_definitions   = ["rate(12 hours)"]
#   snapshot_schedule_force_destroy = true

  # Scheduled actions
#   create_scheduled_action_iam_role = true
#   scheduled_actions = {
#     pause = {
#       name          = "${local.name}-pause"
#       description   = "Pause cluster every night"
#       schedule      = "cron(0 22 * * ? *)"
#       pause_cluster = true
#     }
#     resize = {
#       name        = "${local.name}-resize"
#       description = "Resize cluster (demo only)"
#       schedule    = "cron(00 13 * * ? *)"
#       resize_cluster = {
#         node_type       = "ds2.xlarge"
#         number_of_nodes = 5
#       }
#     }
#     resume = {
#       name           = "${local.name}-resume"
#       description    = "Resume cluster every morning"
#       schedule       = "cron(0 12 * * ? *)"
#       resume_cluster = true
#     }
#   }

  # Endpoint access - only available when using the ra3.x type
#   create_endpoint_access          = true
#   endpoint_name                   = "${local.name}-example"
#   endpoint_subnet_group_name      = aws_redshift_subnet_group.endpoint.id
#   endpoint_vpc_security_group_ids = [module.security_group.security_group_id]

  # Usage limits
#   usage_limits = {
#     currency_scaling = {
#       feature_type  = "concurrency-scaling"
#       limit_type    = "time"
#       amount        = 60
#       breach_action = "emit-metric"
#     }
#     spectrum = {
#       feature_type  = "spectrum"
#       limit_type    = "data-scanned"
#       amount        = 2
#       breach_action = "disable"
#       tags = {
#         Additional = "CustomUsageLimits"
#       }
#     }
#   }

  # Authentication profile
#   authentication_profiles = {
#     example = {
#       name = "example"
#       content = {
#         AllowDBUserOverride = "1"
#         Client_ID           = "ExampleClientID"
#         App_ID              = "example"
#       }
#     }
#     bar = {
#       content = {
#         AllowDBUserOverride = "1"
#         Client_ID           = "ExampleClientID"
#         App_ID              = "bar"
#       }
#     }
#   }

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/redshift"
  version = "~> 5.0"

  name        = local.name
  description = "Redshift security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Allow ingress rules to be accessed only within current VPC
  ingress_rules       = ["redshift-tcp"]
  ingress_cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block, 
                        "172.18.0.0/20"]

  # Allow all rules for all protocols
  egress_rules = ["all-all"]

  tags = local.tags

 # depends_on = [ aws_iam_service_linked_role.redshift ]
}

# resource "aws_iam_service_linked_role" "redshift" {
#   aws_service_name = "redshift.amazonaws.com"
# }

# External schema using AWS Glue Data Catalog
# resource "redshift_schema" "external_from_glue_data_catalog" {
#   name = "sales"
#   owner = "admin"
#   external_schema {
#     database_name = "sales" # Required. Name of the db in glue catalog
#     data_catalog_source {
#      # region = "us-west-2" # Optional. If not specified, Redshift will use the same region as the cluster.
#       iam_role_arns = [
#         aws_iam_role.redshift_role.arn
#       ]
#       # catalog_role_arns = [
#       #   # Optional. If specified, must be at least 1 ARN and not more than 10.
#       #   # If not specified, Redshift will use iam_role_arns for accessing the glue data catalog.
#       #   "arn:aws:iam::123456789012:role/myAthenaRole",
#       #   # ...
#       # ]
#       create_external_database_if_not_exists = true # Optional. Defaults to false.
#     }
#   }
# }

# IAM Role for Redshift
resource "aws_iam_role" "redshift_role" {
  name               = "redshift-spectrum-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "redshift.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for accessing Glue and S3
resource "aws_iam_role_policy" "redshift_role_policy" {
  role = aws_iam_role.redshift_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "glue:*",
          "s3:GetObject",
          "s3:ListBucket",
          "athena:*"
        ],
        Resource = "*"
      }
    ]
  })
}
