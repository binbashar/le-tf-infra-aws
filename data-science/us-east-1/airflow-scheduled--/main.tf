#=============================#
# IAM Role for Scheduler      #
#=============================#
resource "aws_iam_role" "scheduler" {
  count = var.create_scheduler_role ? 1 : 0

  name = local.scheduler_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = local.scheduler_role_name
    }
  )
}

resource "aws_iam_role_policy" "scheduler_mwaa" {
  count = var.create_scheduler_role ? 1 : 0

  name = "${local.scheduler_role_name}-policy"
  role = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "airflow:CreateEnvironment",
          "airflow:TagResource"
        ]
        Resource = "arn:aws:airflow:${var.region}:${data.aws_caller_identity.current.account_id}:environment/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "airflow.amazonaws.com"
          }
        }
      }
    ]
  })
}

#=============================#
# EventBridge Scheduler       #
#=============================#
resource "aws_scheduler_schedule" "mwaa_create_environment" {
  for_each = var.schedules

  name        = "${var.project}-${var.environment}-${each.key}"
  description = each.value.description
  state       = each.value.enabled ? "ENABLED" : "DISABLED"

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.timezone

  flexible_time_window {
    mode                      = each.value.flexible_time_window.mode
    maximum_window_in_minutes = each.value.flexible_time_window.maximum_window_in_minutes
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:mwaa:createEnvironment"
    role_arn = var.create_scheduler_role ? aws_iam_role.scheduler[0].arn : null

    input = jsonencode(merge(
      {
        Name                = "${var.project}-${var.environment}-airflow"
        DagS3Path           = each.value.dag_s3_path
        ExecutionRoleArn    = coalesce(each.value.execution_role_arn, local.mwaa_execution_role_arn)
        SourceBucketArn     = each.value.source_bucket_arn
        EnvironmentClass    = each.value.environment_class
        AirflowVersion      = each.value.airflow_version
        MaxWorkers          = each.value.max_workers
        MinWorkers          = each.value.min_workers
        Schedulers          = each.value.schedulers
        WebserverAccessMode = each.value.webserver_access_mode
        NetworkConfiguration = {
          SubnetIds        = each.value.subnet_ids
          SecurityGroupIds = each.value.security_group_ids
        }
      },
      length(each.value.airflow_configuration_options) > 0 ? {
        AirflowConfigurationOptions = each.value.airflow_configuration_options
      } : {},
      each.value.weekly_maintenance_window_start != null ? {
        WeeklyMaintenanceWindowStart = each.value.weekly_maintenance_window_start
      } : {},
      {
        Tags = merge(
          local.tags,
          {
            Name        = "${var.project}-${var.environment}-airflow"
            ScheduledBy = "EventBridge"
          }
        )
      }
    ))

    retry_policy {
      maximum_event_age_in_seconds = 86400
      maximum_retry_attempts       = 3
    }
  }
}

#=============================#
# CloudWatch Log Group        #
#=============================#
resource "aws_cloudwatch_log_group" "scheduler_logs" {
  name              = "/aws/scheduler/${var.project}-${var.environment}-mwaa-create-env"
  retention_in_days = 7

  tags = merge(
    local.tags,
    {
      Name = "${var.project}-${var.environment}-scheduler-logs"
    }
  )
}
