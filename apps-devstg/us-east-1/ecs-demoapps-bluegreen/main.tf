module "ecs_services" {
  source = "github.com/binbashar/terraform-aws-ecs-bluegreen.git?ref=v1.1.3"

  region                        = "us-east-1"
  task_definition_template_path = "./task-definition.json"

  ecs_cluster_settings          = var.ecs_cluster_settings
  alb_settings                  = var.alb_settings
  services                      = var.services
  networking_settings           = local.networking_settings
  security_settings             = var.security_settings
  deployment_settings           = var.deployment_settings
  git_service                   = var.git_service
  turn_off_services             = var.turn_off_services
  turn_off_on_services_schedule = var.turn_off_on_services_schedule
  tags                          = var.tags
}
