# TEMPORARY - proves the PR gate actually fails on an extended-support version.
# Reverted immediately after the CI run. Excluded from Atlantis in the same commit.
module "cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v21.25.0"

  name               = "selftest"
  kubernetes_version = "1.28"
}
