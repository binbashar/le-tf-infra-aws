#
# Run Atlantis on ECS Fargate
#
module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"
  version = "4.4.1"

  name   = var.name
  create = var.create

  # ECS Cluster
  create_cluster = true
  cluster = {
    configuration = {
      capacity_providers = ["FARGATE"] # NOT WORKING

      default_capacity_provider_strategy = { # NOT WORKING
        FARGATE = {
          weight = 100
          base   = 1
        }
      }
    }

    settings = {
      name  = "containerInsights"
      value = "disabled"
    }
  }

  # Atlantis Container Definition
  atlantis = {
    environment = [
      # {
      #   name  = "ATLANTIS_DISABLE_REPO_LOCKING"
      #   value = "true"
      # },
      {
        name  = "ATLANTIS_LOG_LEVEL"
        value = "info"
      },
      {
        name  = "ATLANTIS_SILENCE_NO_PROJECTS"
        value = "false"
      },
      # {
      #   name  = "ATLANTIS_WRITE_GIT_CREDS"
      #   value = "true"
      # },
      {
        name  = "ATLANTIS_GH_TEAM_ALLOWLIST"
        value = "leverage-ref-architecture-aws-admin:plan, leverage-ref-architecture-aws-admin:apply" # TODO
      },
      {
        name  = "ATLANTIS_REPO_ALLOWLIST"
        value = join(",", ["github.com/binbashar/le-tf-infra-aws"]) # TODO
      },
      {
        name  = "ATLANTIS_REPO_CONFIG_JSON",
        value = jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml"))),
      },
      {
        name  = "ATLANTIS_EMOJI_REACTION"
        value = "eyes"
      },
      {
        name  = "ATLANTIS_SILENCE_VCS_STATUS_NO_PROJECTS"
        value = "true"
      },
      {
        name  = "ATLANTIS_SILENCE_ALLOWLIST_ERRORS"
        value = "true"
      },
      {
        name  = "ATLANTIS_ATLANTIS_URL"
        value = "https://atlantis.binbash.com.ar"
      },
    ]
    secrets = [
      {
        name      = "ATLANTIS_GH_USER"
        valueFrom = "${data.aws_secretsmanager_secret_version.atlantis.arn}:github_user::"
      },
      {
        name      = "ATLANTIS_GH_TOKEN"
        valueFrom = "${data.aws_secretsmanager_secret_version.atlantis.arn}:github_pat::"
      },
      {
        name      = "ATLANTIS_GH_ORG"
        valueFrom = "${data.aws_secretsmanager_secret_version.atlantis.arn}:github_organization::"
      },
      {
        name      = "ATLANTIS_GH_WEBHOOK_SECRET"
        valueFrom = "${data.aws_secretsmanager_secret_version.atlantis.arn}:github_webhook_secret::"
      },
    ]
  }

  # ECS Service
  service = {
    cpu    = "1024"
    memory = "2048"
    # container_definitions = {
    #   datadog-agent = {
    #     name   = "datadog-agent"
    #     image  = "gcr.io/datadoghq/agent:7.46.0"
    #     memory = "400"
    #     cpu    = "400"
    #     environment = [
    #       {
    #         name  = "ECS_FARGATE",
    #         value = "true"
    #       },
    #       {
    #         name  = "DD_API_KEY",
    #         value = data.aws_secretsmanager_secret_version.datadog_api_key_plaintext.secret_string
    #       },
    #       {
    #         name  = "DD_SITE",
    #         value = "datadoghq.com"
    #       },
    #       {
    #         name  = "DD_PROMETHEUS_SCRAPE_ENABLED",
    #         value = "true"
    #       },
    #       {
    #         name  = "DD_PROMETHEUS_SCRAPE_SERVICE_ENDPOINTS",
    #         value = "true"
    #       },
    #       {
    #         name  = "DD_TAGS",
    #         value = "env:${var.env} region:${var.region}"
    #       }
    #     ]
    #     readonly_root_filesystem = false
    #   }
    # }

    # Grant the task permission to read the given secrets from SecretsManager
    task_exec_secret_arns = [
      data.aws_secretsmanager_secret_version.atlantis.arn,
    ]

    # TODO Admin??????
    task_exec_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }

    # TODO Provide Atlantis permission necessary to create/destroy resources???
    tasks_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }

  # VPC Settings
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  service_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # ALB Settings
  alb = {
    enable_deletion_protection = false
    security_group_ingress_rules = {
      gh1 = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv6   = "2606:50c0::/32"
        description = "Github Hooks"
      }
      gh2 = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "185.199.108.0/22"
        description = "Github Hooks"
      }
      gh3 = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "140.82.112.0/20"
        description = "Github Hooks"
      }
      gh4 = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "143.55.64.0/20"
        description = "Github Hooks"
      }
      gh5 = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "192.30.252.0/22"
        description = "Github Hooks"
      }
      gh6 = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv6   = "2a0a:a440::/29"
        description = "Github Hooks"
      }
      oj = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "186.122.225.19/32"
        description = "OJ"
      }
    }
  }
  alb_subnets = data.terraform_remote_state.vpc.outputs.public_subnets

  # Certificate
  create_certificate = false
  certificate_arn    = data.terraform_remote_state.certs.outputs.certificate_arn

  # DNS
  route53_zone_id = data.terraform_remote_state.dns.outputs.aws_public_zone_id

  # Misc
  tags = local.tags
}
