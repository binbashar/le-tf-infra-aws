output "quick_account_name" {
  description = "Amazon Quick account name."
  value       = aws_quicksight_account_subscription.this.account_name
}

output "quick_account_subscription_status" {
  description = "Lifecycle status of the Amazon Quick account subscription."
  value       = aws_quicksight_account_subscription.this.account_subscription_status
}

output "quick_role_groups" {
  description = "Amazon Quick role -> IAM Identity Center group display name."
  value       = merge({ ADMIN = local.quick_admin_group }, local.quick_role_memberships)
}
