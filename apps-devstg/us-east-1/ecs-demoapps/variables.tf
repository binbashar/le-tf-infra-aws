#===========================================#
# ECS Deployment Configuration
#===========================================#
variable "ecs_deployment_type" {
  description = "ECS deployment type: 'rolling' for rolling updates or 'blue-green' for blue-green deployments"
  type        = string
  default     = "rolling"

  validation {
    condition     = contains(["rolling", "blue-green"], var.ecs_deployment_type)
    error_message = "ECS deployment type must be either 'rolling' or 'blue-green'."
  }
}