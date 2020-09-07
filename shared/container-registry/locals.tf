locals {
  default_lifecycle_policy_rules = [
    "${module.ecr_lifecycle_rule_default_policy_bycount.policy_rule}",
  ]

  #
  # List of repositories to create and their attributes
  #
  repository_list = {
    bb_leverage = {
      create = true
      name = "bb/leverage"
      read_permissions = [
        "arn:aws:iam::${var.appsdevstg_account_id}:root",
        "arn:aws:iam::${var.appsprd_account_id}:root",
      ]
      write_permissions = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}
