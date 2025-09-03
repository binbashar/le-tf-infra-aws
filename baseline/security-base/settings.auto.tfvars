environment = "dev"
sso_role = "DevOps"

inputs = {
  "apps-devstg" = {
    module_version = "2.3.0"
    ebs_encryption = false
    block_public_acls = true
    block_public_policy = true
    sns_topic_name_monitoring_security = "arn:aws:sns:us-east-1:123456789012:monitoring-security"
    send_sns = true
  }
  "apps-prd" = {
    module_version = "2.2.0"
    ebs_encryption = true
    block_public_acls = true
    block_public_policy = true
    sns_topic_name_monitoring_security = "arn:aws:sns:us-east-1:923456789012:monitoring-security"
    send_sns = true
  }
  "data-science" = {
    module_version = "2.2.0"
    ebs_encryption = true
    block_public_acls = true
    block_public_policy = true
    sns_topic_name_monitoring_security = "arn:aws:sns:us-east-1:923456789012:monitoring-security"
    send_sns = true
  }
  "network" = {
    module_version = "2.2.0"
    ebs_encryption = true
    block_public_acls = true
    block_public_policy = true
    sns_topic_name_monitoring_security = "arn:aws:sns:us-east-1:923456789012:monitoring-security"
    send_sns = true
  }
  "shared" = {
    module_version = "2.2.0"
    ebs_encryption = true
    block_public_acls = true
    block_public_policy = true
    sns_topic_name_monitoring_security = "arn:aws:sns:us-east-1:923456789012:monitoring-security"
    send_sns = true
  }
  "default" = {
    module_version = "2.9.1"
    ebs_encryption = false
    block_public_acls = true
    block_public_policy = true
    sns_topic_name_monitoring_security = "arn:aws:sns:us-east-1:705418344519:monitoring-security"
    send_sns = true
  }
}


