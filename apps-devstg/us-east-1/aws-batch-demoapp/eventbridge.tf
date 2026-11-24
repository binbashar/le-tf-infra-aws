#===================================================================#
# EventBridge: job scheduler (Scheduler) + failure notifications    #
#===================================================================#
locals {
  # EventBridge Scheduler universal target for the Batch SubmitJob API. The input uses the
  # API's request parameters in PascalCase. JobDefinition is the name only, so every run
  # uses the latest ACTIVE revision (including revisions registered by a CI/CD pipeline).
  eventbridge_schedules = {
    for k, v in var.schedules : "${local.name}-${k}" => {
      description         = coalesce(v.description, "Submits the ${v.job_definition} AWS Batch job to ${local.name}")
      schedule_expression = v.schedule_expression
      timezone            = v.timezone
      state               = v.enabled
      arn                 = "arn:aws:scheduler:::aws-sdk:batch:submitJob"
      input = jsonencode(merge(
        {
          JobName       = k
          JobQueue      = module.batch.job_queues["main"].arn
          JobDefinition = module.batch.job_definitions[v.job_definition].name
        },
        v.command != null || length(v.environment) > 0 ? {
          ContainerOverrides = merge(
            v.command != null ? { Command = v.command } : {},
            length(v.environment) > 0 ? {
              Environment = [for name, value in v.environment : { Name = name, Value = value }]
            } : {},
          )
        } : {},
      ))
    }
  }

  failure_rule_name = "${local.name}-job-state"

  eventbridge_rules = var.failure_notifications.enabled ? {
    (local.failure_rule_name) = {
      description = "AWS Batch ${local.name} job state changes to ${join(", ", var.failure_notifications.statuses)}"
      event_pattern = jsonencode({
        source        = ["aws.batch"]
        "detail-type" = ["Batch Job State Change"]
        detail = {
          status   = var.failure_notifications.statuses
          jobQueue = [module.batch.job_queues["main"].arn]
        }
      })
    }
  } : {}

  # The Slack notifier renders a plain string message, so the event is turned into a readable line.
  eventbridge_targets = var.failure_notifications.enabled ? {
    (local.failure_rule_name) = [
      {
        name = "slack-sns"
        arn  = local.failure_notifications_sns_topic_arn
        input_transformer = {
          input_paths = {
            jobName      = "$.detail.jobName"
            jobId        = "$.detail.jobId"
            status       = "$.detail.status"
            statusReason = "$.detail.statusReason"
            account      = "$.account"
            region       = "$.region"
          }
          input_template = "\"AWS Batch job <jobName> (<jobId>) in ${local.name} is <status>: <statusReason>. Account <account>, region <region>.\""
        }
      }
    ]
  } : {}
}

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.4.1"

  create = length(local.eventbridge_schedules) > 0 || var.failure_notifications.enabled

  # Use the account's default event bus (AWS Batch publishes its events there)
  create_bus = false
  bus_name   = "default"

  # The module enables log delivery for the bus by default; this layer must not change the shared default bus
  create_log_delivery_source = false
  create_log_delivery        = false

  append_rule_postfix     = false
  append_schedule_postfix = false

  rules     = local.eventbridge_rules
  targets   = local.eventbridge_targets
  schedules = local.eventbridge_schedules

  # IAM role assumed by EventBridge Scheduler to submit the jobs (the SNS target uses the topic policy instead)
  create_role      = length(local.eventbridge_schedules) > 0
  role_name        = "${local.name}-scheduler"
  role_description = "EventBridge Scheduler role that submits ${local.name} AWS Batch jobs"

  attach_policy_statements = length(local.eventbridge_schedules) > 0
  policy_statements = {
    submit_job = {
      effect  = "Allow"
      actions = ["batch:SubmitJob"]
      resources = concat(
        [module.batch.job_queues["main"].arn],
        [for k in distinct([for s in var.schedules : s.job_definition]) :
          "arn:aws:batch:${var.region}:${data.aws_caller_identity.current.account_id}:job-definition/${module.batch.job_definitions[k].name}:*"
        ],
      )
    }
  }

  tags = local.tags
}
