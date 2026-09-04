module "elasticache_redis" {
  source = "github.com/terraform-aws-modules/terraform-aws-elasticache.git?ref=v1.0.0"

  engine_version = var.engine_version
}
