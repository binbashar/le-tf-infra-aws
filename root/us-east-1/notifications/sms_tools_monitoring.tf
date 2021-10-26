module "notify_sms" {
  source = "github.com/binbashar/terraform-aws-sns-topic.git?ref=0.19.2"

  name = var.sns_topic_name_sms

  subscribers = {
    phone1 = {
      protocol               = "sms"
      endpoint               = data.vault_generic_secret.notifications.data["phone1"]
      endpoint_auto_confirms = true
      raw_message_delivery   = true
    }
    #phone2 = {
    #  protocol               = "sms"
    #  endpoint               = data.vault_generic_secret.notifications.data["phone2"]
    #  endpoint_auto_confirms = true
    #  raw_message_delivery   = true
    #}
    #phone3 = {
    #  protocol               = "sms"
    #  endpoint               = data.vault_generic_secret.notifications.data["phone3"]
    #  endpoint_auto_confirms = true
    #  raw_message_delivery   = true
    #}
  }

  sqs_dlq_enabled = false
}
