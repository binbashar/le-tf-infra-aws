#
# Providers
#
provider "kubernetes" {
  host                   = var.kubernetes_host
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
  client_key             = base64decode(var.kubernetes_client_key)
  client_certificate     = base64decode(var.kubernetes_client_certificate)
}

provider "helm" {
  kubernetes {
    host                   = var.kubernetes_host
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
    client_key             = base64decode(var.kubernetes_client_key)
    client_certificate     = base64decode(var.kubernetes_client_certificate)
  }
}

#
# Backend Config (partial)
#
terraform {
  required_version = ">= 0.14.11"

  required_providers {
    helm       = "~> 2.1.0"
    kubernetes = "~> 2.0.2"
  }

  backend "s3" {
    key = "apps-devstg/k8s-kind/k8s-resources/terraform.tfstate"
  }
}
