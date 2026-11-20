#
# Workload budgets
#
# One monthly budget per workload, scoped to the workload's Purpose tag (activated
# in cost_allocation_tags.tf). They live here because the payer account can read
# every linked account's tagged spend, while a workload's own deploy role may not
# be allowed to create budgets in its account.
#
# Each budget emails the workload's owners rather than the costs SNS topic: that
# topic pages the account-wide SMS list, which is for the whole bill.
#
# Bedrock model calls carry no resource tag, so a workload's model spend is not in
# its budget; the workload watches its call volume with its own alarm.
#
resource "aws_budgets_budget" "workload" {
  for_each = var.workload_budgets

  name         = "${var.project}-${var.environment}-workload-${each.key}"
  budget_type  = "COST"
  limit_amount = format("%.2f", each.value.limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = [format("user:Purpose$%s", each.key)]
  }

  dynamic "notification" {
    for_each = ["ACTUAL", "FORECASTED"]
    content {
      notification_type          = notification.value
      comparison_operator        = "GREATER_THAN"
      threshold                  = 100
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = each.value.emails
    }
  }

  tags = local.tags
}
