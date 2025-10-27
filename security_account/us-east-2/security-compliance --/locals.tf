locals {
  region = var.region == null ? data.aws_region.current.name : var.region
}
