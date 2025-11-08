#===========================================#
# ECS Deployment Configuration
#===========================================#
variable "ecs_deployment_type" {
  description = "ECS deployment type: 'rolling' for rolling updates or 'blue-green' for blue-green deployments"
  type        = string
  default     = "ROLLING"

  validation {
    condition     = contains(["ROLLING", "BLUE_GREEN"], var.ecs_deployment_type)
    error_message = "ECS deployment type must be either 'ROLLING' or 'BLUE_GREEN'."
  }
}

#===========================================#
# ECS Service Definitions
#===========================================#
variable "service_definitions" {
  description = "ECS service and container definitions. Image versions are dynamically sourced from SSM parameters."
  type = map(object({
    cpu    = number
    memory = number
    containers = map(object({
      image       = string
      cpu         = number
      memory      = number
      environment = optional(map(string), {})
      ports       = optional(map(number), {})
      entrypoint  = optional(list(string), [])
      dependencies = optional(list(object({
        containerName = string
        condition     = string
      })), [])
      essential = optional(bool, true)
    }))
  }))

  default = {
    emojivoto-web = {
      cpu    = 1024
      memory = 4096

      containers = {
        web = {
          image  = "523857393444.dkr.ecr.us-east-1.amazonaws.com/demo-emojivoto/web"
          cpu    = 512
          memory = 2048

          environment = {
            WEB_PORT       = "8080"
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
            GRPC_PORT = "8081"
            PROM_PORT = "8801"
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
            GRPC_PORT = "8082"
            PROM_PORT = "8802"
          }

          ports = {
            grpc-emoji = 8082
            prom-emoji = 8802
          }
        }
      }
    }
  }
}

#===========================================#
# Routing Configuration
#===========================================#
variable "routing" {
  description = "ALB routing configuration for ECS containers"
  type = map(map(object({
    subdomain        = string
    port             = number
    protocol_version = optional(string, "HTTP1")
    health_check = optional(object({
      matcher = optional(string)
    }), {})
  })))

  default = {
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
}