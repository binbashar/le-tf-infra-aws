
locals {
  name        = "${var.project}-${var.environment}-demoapps"
  base_domain = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_domain_name

  services = {
    emojivoto = {
      cpu    = 2048
      memory = 8192

      containers = {
        web = {
          image   = "docker.l5d.io/buoyantio/emojivoto-web"
          version = "v11"

          cpu    = 512
          memory = 2048

          environment = {
            WEB_PORT       = local.routing.emojivoto.web.port
            EMOJISVC_HOST  = "${local.routing.emojivoto.emoji-api.subdomain}.${local.base_domain}"
            VOTINGSVC_HOST = "${local.routing.emojivoto.voting-api.subdomain}.${local.base_domain}"
            INDEX_BUNDLE   = "dist/index_bundle.js"
          }

          ports = {
            http = local.routing.emojivoto.web.port
          }
        }

        voting-api = {
          image   = "docker.l5d.io/buoyantio/emojivoto-voting-svc"
          version = "v11"

          cpu    = 512
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
          version = "v11"

          cpu    = 512
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
          version = "v11"

          cpu    = 512
          memory = 2048

          environment = {
            WEB_HOST = "${local.routing.emojivoto.web.subdomain}.${local.base_domain}"
          }
        }
      }
    }
  }

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
  }
}
