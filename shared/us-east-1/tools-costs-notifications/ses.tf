# Creating SES sender identity
resource "aws_ses_email_identity" "monthly_services_usage_sender" {
  email = var.sender_email
}