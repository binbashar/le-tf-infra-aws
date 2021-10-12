locals {
  labels = {
    "app.kubernetes.io/managed-by" = "Terraform"
    "app.kubernetes.io/part-of"    = var.environment
  }

  demoapps = {
    sockshop = {
      templateValues = {
        valueFile = var.enable_demoapps_sockshop_aws_integration ? "values-aws.yaml" : "values.yaml"
      }
    }

    gmd = {
      templateValues = {
        valueFile = var.enable_demoapps_gmd_aws_integration ? "values-aws.yaml" : "values.yaml"
      }
    }
  }
}
