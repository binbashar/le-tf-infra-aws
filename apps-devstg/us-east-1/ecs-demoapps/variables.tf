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