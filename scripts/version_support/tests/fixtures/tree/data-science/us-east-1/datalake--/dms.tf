module "dms" {
  source = "github.com/terraform-aws-modules/terraform-aws-dms.git?ref=v2.0.0"

  repl_instance_engine_version = "3.5.3"
}
