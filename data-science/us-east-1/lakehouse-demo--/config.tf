#=============================#
# AWS Provider Settings       #
#=============================#
provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "sql" {
  alias = "mysql"
  url   = "mysql://${data.terraform_remote_state.aurora_mysql.outputs.cluster_master_username}:${data.terraform_remote_state.aurora_mysql.outputs.cluster_master_password}@tcp(${data.terraform_remote_state.aurora_mysql.outputs.cluster_endpoint}:3306)/${data.terraform_remote_state.aurora_mysql.outputs.cluster_database_name}"
}

provider "sql" {
  alias = "postgres"
  url   = "postgres://${data.terraform_remote_state.aurora_postgres.outputs.cluster_master_username}:${data.terraform_remote_state.aurora_postgres.outputs.cluster_master_password}@${data.terraform_remote_state.aurora_postgres.outputs.cluster_endpoint}:5432/${data.terraform_remote_state.aurora_postgres.outputs.cluster_database_name}?sslmode=disable"
}

provider "redshift" {
  host     = module.redshift.cluster_hostname
  username = "admin"
  password = "ILO~p;yo!7Q%p*v:"
  database = "demo"
  # temporary_credentials {
  #   cluster_identifier = module.redshift.cluster_identifier
  # }
}

#=============================#
# Backend Config (partial)    #
#=============================#
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = "~> 5.0"
    sql = {
      source  = "paultyng/sql"
      version = "0.5.0"
    }
    redshift = {
      source = "brainly/redshift"
      version = "1.1.0"
    }
  }

  backend "s3" {
    key = "data-science/datalake-demo/terraform.tfstate"
  }
}

#=============================#
# Data sources                #
#=============================#
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "secrets" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/secrets-manager/terraform.tfstate"
  }
}

data "terraform_remote_state" "secrets_apps_devstg" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/secrets-manager/terraform.tfstate"
  }
}

data "terraform_remote_state" "aurora_mysql" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/databases-aurora-mysql/terraform.tfstate"
  }
}

data "terraform_remote_state" "aurora_postgres" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "bb-apps-devstg-devops"
    bucket  = "bb-apps-devstg-terraform-backend"
    key     = "apps-devstg/databases-aurora-pgsql/terraform.tfstate"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"
  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/security-keys/terraform.tfstate"
  }
}