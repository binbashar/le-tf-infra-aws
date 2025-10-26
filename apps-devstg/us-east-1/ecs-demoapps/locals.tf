
locals {
  environment = replace(var.environment, "apps-", "")
  name        = "${var.project}-${local.environment}-demoapps"
  base_domain = "${local.environment}.${data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_domain_name}"

  # ✅ SINGLE SOURCE OF TRUTH - Define service structure once
  service_definitions = {
    emojivoto-web = {
      cpu    = 1024
      memory = 4096

      containers = {
        web = {
          image  = "523857393444.dkr.ecr.us-east-1.amazonaws.com/demo-emojivoto/web"
          cpu    = 512
          memory = 2048

          environment = {
            WEB_PORT       = 8080
            EMOJISVC_HOST  = "localhost:8082"
            VOTINGSVC_HOST = "localhost:8081"
            INDEX_BUNDLE   = "dist/index_bundle.js"
          }

          ports = {
            http = 8080
          }
        }

        vote-bot = {
          image  = "523857393444.dkr.ecr.us-east-1.amazonaws.com/demo-emojivoto/web"
          cpu    = 512
          memory = 2048

          environment = {
            WEB_HOST = "localhost:8080"
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
    emojivoto-svc = {
      cpu    = 512
      memory = 2048

      containers = {

        voting-api = {
          image  = "523857393444.dkr.ecr.us-east-1.amazonaws.com/demo-emojivoto/voting-svc"
          cpu    = 512
          memory = 2048

          environment = {
            GRPC_PORT = 8081
            PROM_PORT = 8801
          }

          ports = {
            grpc-voting = 8081
            prom-voting = 8801
          }
        }
      }
    }
    emojivoto-api = {
      cpu    = 512
      memory = 2048

      containers = {

        emoji-api = {
          image  = "523857393444.dkr.ecr.us-east-1.amazonaws.com/demo-emojivoto/emoji-svc"
          cpu    = 512
          memory = 2048

          environment = {
            GRPC_PORT = 8082
            PROM_PORT = 8802
          }

          ports = {
            grpc-emoji = 8082
            prom-emoji = 8802
          }
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
    emojivoto-web = {
      web = {
        subdomain = "emojivoto.ecs"
        port      = 8080
        health_check = {
          matcher = "200-404"
        }
      }
    }
    emojivoto-svc = {
      voting-api = {
        subdomain        = "emojivoto-voting.ecs"
        port             = 8081
        protocol_version = "GRPC"
      }
    }
    emojivoto-api = {
      emoji-api = {
        subdomain        = "emojivoto-emoji.ecs"
        port             = 8082
        protocol_version = "GRPC"
      }
    }
  }
  target_groups = merge(flatten([for service, tasks in local.routing : [tasks]])...)

  # All possible listeners defined
  all_listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = data.terraform_remote_state.certs.outputs.certificate_arn

      rules = { for container_name, container_values in local.target_groups :
        container_name => {
          actions = [
            {
              forward = {
                target_group_key = container_name
              }
            }
          ]

          conditions = [
            {
              host_header = {
                values = ["${container_values.subdomain}.${local.base_domain}"]
              }
            }
          ]
        }
      }
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
    test-http-https-redirect = {
      enabled  = var.ecs_deployment_type == "BLUE_GREEN"
      port     = 8080
      protocol = "HTTP"
      redirect = {
        port        = 8443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    test-https = {
      enabled         = var.ecs_deployment_type == "BLUE_GREEN"
      port            = 8443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = data.terraform_remote_state.certs.outputs.certificate_arn

      rules = { for container_name, container_values in local.target_groups :
        "${container_name}-test" => {
          actions = [
            {
              forward = {
                target_group_key = "${container_name}-bg"
              }
            }
          ]

          conditions = [
            {
              host_header = {
                values = ["${container_values.subdomain}.${local.base_domain}"]
              }
            }
          ]
        }
      }
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }

  # Filter listeners based on enabled flag
  alb_listeners = {
    for name, config in local.all_listeners :
    name => { for k, v in config : k => v if k != "enabled" }
    if try(config.enabled, true)
  }

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
