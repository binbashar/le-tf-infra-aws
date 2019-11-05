module "nuke_everything_older_than_7d" {
  source = "git::git@github.com:binbashar/terraform-aws-lambda-nuke.git?ref=2.1.2"

  name                           = var.name
  cloudwatch_schedule_expression = var.cloudwatch_schedule_expression
  exclude_resources              = var.exclude_resources
  older_than                     = var.older_than
}