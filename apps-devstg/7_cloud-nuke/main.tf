module "nuke_everything_older_than_7d" {
  source = "github.com/binbashar/terraform-aws-lambda-nuke.git?ref=2.3.0"

  name                           = "${var.project}-${var.environment}-${var.name}"
  cloudwatch_schedule_expression = var.cloudwatch_schedule_expression
  exclude_resources              = var.exclude_resources
  older_than                     = var.older_than
}
