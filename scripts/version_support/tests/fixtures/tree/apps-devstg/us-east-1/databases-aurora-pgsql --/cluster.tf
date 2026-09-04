module "aurora_postgresql" {
  source = "github.com/terraform-aws-modules/terraform-aws-rds-aurora.git?ref=v9.0.0"

  engine         = local.engine
  engine_version = "14.8"
}
