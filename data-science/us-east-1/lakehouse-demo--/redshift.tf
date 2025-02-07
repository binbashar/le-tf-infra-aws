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


  # Subnet group
  subnet_group_name        = "${local.name}-subnet-group"
  subnet_group_description = "Custom subnet group for ${local.name} cluster"


  create_snapshot_schedule = false

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
}


##################################################################################################
# Run the following query to grant access to specific role to use the awsdatacatalog database.   # 
# ################################################################################################
resource "aws_redshiftdata_statement" "grant_usage" {
    for_each           = toset(local.roles_to_grant_usage)
  cluster_identifier = module.redshift.cluster_identifier
  database           = "demo"
  sql                = "GRANT USAGE ON DATABASE awsdatacatalog to \"IAMR:${each.value}\""
  secret_arn = module.redshift.master_password_secret_arn
}

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

