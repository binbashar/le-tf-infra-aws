#======================================
# SNS: Topics & Subscriptions
#======================================

module "topic_shippingservice" {
  source = "github.com/terraform-aws-modules/terraform-aws-sns.git?ref=v6.2.1"

  name = "ShippingServiceTopic"

  subscriptions = {
    email = {
      protocol               = "email"
      endpoint_auto_confirms = true
      endpoint               = var.recipient_email_address
    }
  }

  tags = local.tags
}
