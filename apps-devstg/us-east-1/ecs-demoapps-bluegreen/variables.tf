variable "ecs_cluster_settings" {
  type        = any
  description = "ECS Cluster Settings"
  default     = {}
}

variable "alb_settings" {
  type        = any
  description = "ALB Settings"
  default     = {}
}

variable "services" {
  type        = any
  description = "ECS Backend Services Configuration Details"
  default     = {}
}


variable "networking_settings" {
  type        = any
  description = "Networking Settings"
  default     = {}
}

variable "security_settings" {
  type        = any
  description = "Security Settings"
  default     = {}
}

variable "deployment_settings" {
  type        = any
  description = "Deployment Settings"
  default     = {}
}

variable "git_service" {
  type = object({
    connection_name = string
    type            = string
  })
  description = "Git Service Configuration for CodePipeline"
  default = {
    connection_name = "github"
    type            = "github"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resources"
  default     = {}
}

variable "task_definition_template_path" {
  type        = string
  description = "Path to the task definition template"
  default     = "task-definition-template.json"
}

variable "turn_off_services" {
  type        = bool
  description = "Turn off services ecs cluster"
  default     = false
}

variable "turn_off_on_services_schedule" {
  type = object({
    schedule_off_expression = string
    schedule_on_expression  = string
  })
  description = "Turn off and on services ecs cluster schedule"
  default = {
    schedule_off_expression = "cron(0 23 ? * MON,TUE,WED,THUR,FRI *)"
    schedule_on_expression  = "cron(0 0 ? * MON,TUE,WED,THUR,FRI *)"
  }
}
