
locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-demoapps"
  base_domain = "${local.environment}.${data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_domain_name}"

  # ✅ SINGLE SOURCE OF TRUTH - Define service structure once
  service_definitions = {
    emojivoto = {
      cpu    = 2048
      memory = 8192

      containers = {
        web = {
          image   = "docker.l5d.io/buoyantio/emojivoto-web"
          cpu     = 512
          memory = 2048

          environment = {
            WEB_PORT       = local.routing.emojivoto.web.port
            EMOJISVC_HOST  = "localhost:${local.routing.emojivoto.emoji-api.port}"
            VOTINGSVC_HOST = "localhost:${local.routing.emojivoto.voting-api.port}"
            INDEX_BUNDLE   = "dist/index_bundle.js"
          }

          ports = {
            http = local.routing.emojivoto.web.port
          }
        }

        voting-api = {
          image   = "docker.l5d.io/buoyantio/emojivoto-voting-svc"
          cpu     = 512
          memory = 2048

          environment = {
            GRPC_PORT = local.routing.emojivoto.voting-api.port
            PROM_PORT = 8801
          }

          ports = {
            grpc-voting = local.routing.emojivoto.voting-api.port
            prom-voting = 8801
          }
        }

        emoji-api = {
          image   = "docker.l5d.io/buoyantio/emojivoto-emoji-svc"
          cpu     = 512
          memory = 2048

          environment = {
            GRPC_PORT = local.routing.emojivoto.emoji-api.port
            PROM_PORT = 8802
          }

          ports = {
            grpc-emoji = local.routing.emojivoto.emoji-api.port
            prom-emoji = 8802
          }
        }

        vote-bot = {
          image   = "docker.l5d.io/buoyantio/emojivoto-web"
          cpu     = 512
          memory = 2048

          environment = {
            WEB_HOST = "localhost:${local.routing.emojivoto.web.port}"
          }

          entrypoint = ["emojivoto-vote-bot"]

          dependencies = [{
            containerName = "web"
            condition     = "START"
          }]

          essential = false
        }
      }
    }
  }

  # ✅ AUTO-GENERATE parameter paths using CONVENTION
  # Convention: /ecs/{environment}/{service_name}/{container_name}/image-tag
  container_parameters = flatten([
    for service_name, service_config in local.service_definitions : [
      for container_name, container_config in service_config.containers : {
        key  = "${service_name}_${container_name}"
        path = "/ecs/${local.environment}/${service_name}/${container_name}/image-tag"
      }
    ]
  ])

  parameter_paths = { for item in local.container_parameters : item.key => item.path }

  routing = {
    emojivoto = {
      web = {
        subdomain = "emojivoto.ecs"
        port      = 8080
        health_check = {
          matcher = "200-404"
        }
      }
      voting-api = {
        subdomain        = "emojivoto-voting.ecs"
        port             = 8081
        protocol_version = "GRPC"
      }
      emoji-api = {
        subdomain        = "emojivoto-emoji.ecs"
        port             = 8082
        protocol_version = "GRPC"
      }
    }
  }
  target_groups = merge(flatten([for service, tasks in local.routing : [tasks]])...)

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}

# ✅ Dynamic parameter lookup
data "aws_ssm_parameter" "image_tags" {
  for_each = local.parameter_paths
  name     = each.value
}

locals {
  # ✅ AUTO-REBUILD services with dynamic versions
  services = {
    for service_name, service_config in local.service_definitions :
    service_name => merge(service_config, {
      containers = {
        for container_name, container_config in service_config.containers :
        container_name => merge(container_config, {
          version = data.aws_ssm_parameter.image_tags["${service_name}_${container_name}"].value
        })
      }
    })
  }
}
