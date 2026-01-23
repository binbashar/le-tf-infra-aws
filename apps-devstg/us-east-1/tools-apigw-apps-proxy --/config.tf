#======================================
# AWS Provider Settings
#======================================
provider "aws" {
  region  = var.region
  profile = var.profile
}
provider "aws" {
  alias   = "shared"
  region  = var.region
  profile = "${var.project}-shared-devops"
}

#======================================
# Backend Config (partial)
#======================================
terraform {
  required_version = "~> 1.2"

  required_providers {
    aws = "~> 4.30"
  }

  backend "s3" {
    key = "apps-dev/us-east-1/apigw-apps-proxy/terraform.tfstate"
  }
}

#======================================
# Data sources
#======================================
data "terraform_remote_state" "eks-vpc" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/k8s-eks/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "certs" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-certs/binbash.com.ar/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-dns" {
  backend = "s3"
  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/dns/binbash.com.ar/terraform.tfstate"
  }
}

# Find the NLB that matches the following tags
data "aws_lbs" "nlb" {
  tags = {
    "Environment"                               = local.env
    "kubernetes.io/cluster/dr-apps-dev-eks-1ry" = "owned"
    "kubernetes.io/service-name"                = "ingress-nginx/ingress-nginx-private-controller"
  }
}
# Then we find the listener that matches that NLB's given port
data "aws_lb_listener" "nlb_https" {
  load_balancer_arn = one(data.aws_lbs.nlb.arns)
  port              = 443
}
