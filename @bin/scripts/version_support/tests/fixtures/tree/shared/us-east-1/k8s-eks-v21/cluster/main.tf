module "cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v21.25.0"

  name               = "test-v21"
  kubernetes_version = var.cluster_version
}
