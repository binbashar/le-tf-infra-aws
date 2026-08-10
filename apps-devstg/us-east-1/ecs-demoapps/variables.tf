#===========================================#
# ECS Deployment Configuration
#===========================================#
variable "ecs_deployment_type" {
  description = "ECS deployment type: 'ROLLING' for rolling updates or 'BLUE_GREEN' for blue-green deployments"
  type        = string
  default     = "BLUE_GREEN"

  validation {
    condition     = contains(["ROLLING", "BLUE_GREEN"], var.ecs_deployment_type)
    error_message = "ECS deployment type must be either 'ROLLING' or 'BLUE_GREEN'."
  }
}

#===========================================#
# ECS Deployment Tuning
#===========================================#
variable "ecs_deployment_bake_time_minutes" {
  description = "Minutes ECS waits after a blue-green deployment before marking it stable"
  type        = number
  default     = 5

  validation {
    condition     = var.ecs_deployment_bake_time_minutes > 0
    error_message = "Bake time must be greater than 0 minutes."
  }
}

variable "ecs_deployment_maximum_percent" {
  description = "Maximum percentage of tasks that can run during a deployment (surge capacity)"
  type        = number
  default     = 200

  validation {
    condition     = var.ecs_deployment_maximum_percent >= 100
    error_message = "Maximum deployment percent must be at least 100."
  }
}

variable "ecs_deployment_minimum_healthy_percent_rolling" {
  description = "Minimum percentage of healthy tasks required during a rolling deployment"
  type        = number
  default     = 50

  validation {
    condition     = var.ecs_deployment_minimum_healthy_percent_rolling >= 0 && var.ecs_deployment_minimum_healthy_percent_rolling < 100
    error_message = "Minimum healthy percent for rolling must be between 0 and 99."
  }
}

variable "ecs_deployment_minimum_healthy_percent_blue_green" {
  description = "Minimum percentage of healthy tasks required during a blue-green deployment"
  type        = number
  default     = 100

  validation {
    condition     = var.ecs_deployment_minimum_healthy_percent_blue_green >= 0 && var.ecs_deployment_minimum_healthy_percent_blue_green <= 100
    error_message = "Minimum healthy percent for blue-green must be between 0 and 100."
  }
}

#===========================================#
# ECS Service Definitions
#===========================================#
variable "service_definitions" {
  description = "ECS service and container definitions. Image versions are dynamically sourced from SSM parameters."
  type = map(object({
    cpu                           = number
    memory                        = number
    ephemeral_storage_size_in_gib = optional(number) # Optional: only set if > 20 GiB needed (range: 21-200 GiB)
    volumes = optional(map(object({
      type           = string
      file_system_id = optional(string) # Required for EFS volumes
    })), {})
    containers = map(object({
      image                  = string
      cpu                    = number
      memory                 = number
      readonlyRootFilesystem = optional(bool, false) # Allow writable filesystem by default
      environment            = optional(map(string), {})
      secrets                = optional(map(string), {}) # Map of secret name to Secrets Manager ARN or SSM Parameter ARN
      ports                  = optional(map(number), {})
      entrypoint             = optional(list(string), [])
      mount_points = optional(map(object({
        source_volume  = string
        container_path = string
        read_only      = bool
      })), {})
      dependencies = optional(list(object({
        containerName = string
        condition     = string
      })), [])
      essential = optional(bool, true)
    }))
  }))

  default = {
    emojivoto = {
      cpu    = 2048
      memory = 8192

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
          cpu    = 256
          memory = 512

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
      path    = optional(string)
    }), {})
  })))

  validation {
    condition = (
      length(flatten([for service, containers in var.routing : keys(containers)])) ==
      length(toset(flatten([for service, containers in var.routing : keys(containers)])))
    )
    error_message = "Container names within 'routing' must be globally unique across all services. Duplicate keys cause silent ALB target group overwrites."
  }

  default = {
    emojivoto = {
      web = {
        subdomain = "emojivoto.ecs"
        port      = 8080
        health_check = {
          matcher = "200-404"
        }
      }
    }
  }
}