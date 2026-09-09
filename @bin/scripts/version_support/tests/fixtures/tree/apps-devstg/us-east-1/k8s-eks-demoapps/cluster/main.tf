module "cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v21.0.0"

  cluster_name    = "test"
  cluster_version = var.cluster_version
}
