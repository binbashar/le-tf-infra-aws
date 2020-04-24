#
# Daily schedule stop / start resources
#

# Stop
#
module "schedule_ec2_stop_daily_midnight" {
  source = "github.com/binbashar/terraform-aws-lambda-scheduler-stop-start?ref=2.8.0"
  name                           = "${var.project}-${var.environment}-schedule-stop-ec2"

  # Define the aws cloudwatch event rule schedule expression,
  # eg1: monday to friday at 22hs cron(0 22 ? * MON-FRI *)
  # eg2: once a week every friday at 00hs cron(0 00 ? * FRI *)
  # eg3: everyday at 00hs cron(0 00 * * ? *)
  cloudwatch_schedule_expression = "cron(0 00 * * ? *)"

  # Define schedule action to apply on resources
  schedule_action                = "stop"

  # Enable scheduling on ec2 instance resources
  ec2_schedule                   = "true"

  # Enable scheduling on ec2 spot, ec2 autoscaling and rds
  spot_schedule                  = "false" # to activate = "true"
  rds_schedule                   = "false" # to activate = "true"
  autoscaling_schedule           = "false" # to activate = "terminate"

  # Set the tag use for identify resources to stop or start
  resources_tag = {
    key   = "ScheduleStopDaily"
    value = "true"
  }
}

# Start
#
module "schedule_ec2_start_daily_morning" {
  source = "github.com/binbashar/terraform-aws-lambda-scheduler-stop-start?ref=2.8.0"
  name                           = "${var.project}-${var.environment}-schedule-start-ec2"

  # Define the aws cloudwatch event rule schedule expression,
  # eg1: monday to friday at 22hs cron(0 22 ? * MON-FRI *)
  # eg2: once a week every friday at 00hs cron(0 00 ? * FRI *)
  # eg3: everyday at 00hs cron(0 00 * * ? *)
  cloudwatch_schedule_expression = "cron(6 00 * * ? *)"

  # Define schedule action to apply on resources
  schedule_action                = "start"

  # Enable scheduling on ec2 instance resources
  ec2_schedule                   = "true"

  # Enable scheduling on ec2 spot, ec2 autoscaling and rds
  spot_schedule                  = "false" # to activate = "true"
  rds_schedule                   = "false" # to activate = "true"
  autoscaling_schedule           = "false" # to activate = "terminate"

  # Set the tag use for identify resources to stop or start
  resources_tag = {
    key   = "ScheduleStartDaily"
    value = "true"
  }
}


