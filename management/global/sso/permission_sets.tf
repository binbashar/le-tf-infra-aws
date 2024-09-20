module "permission_sets" {
  source = "github.com/binbashar/terraform-aws-sso.git//modules/permission-sets?ref=0.7.1"

  permission_sets = [
    {
      name                                = "Administrator"
      description                         = "Provides full access to AWS services and resources."
      relay_state                         = local.default_relay_state
      session_duration                    = local.default_session_duration
      tags                                = local.tags
      inline_policy                       = ""
      policy_attachments                  = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "DevOps"
      description                         = "Provides full access to many AWS services and resources except billing."
      relay_state                         = local.default_relay_state
      session_duration                    = "PT2H"
      tags                                = local.tags
      inline_policy                       = data.aws_iam_policy_document.devops.json
      policy_attachments                  = []
      customer_managed_policy_attachments = []
    },
    {
      name                                = "FinOps"
      description                         = "Provides access to billing and cost management."
      relay_state                         = local.default_relay_state
      session_duration                    = local.default_session_duration
      tags                                = local.tags
      inline_policy                       = ""
      policy_attachments                  = ["arn:aws:iam::aws:policy/job-function/Billing"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "SecurityAuditor"
      description                         = "Provides access for security auditing."
      relay_state                         = local.default_relay_state
      session_duration                    = local.default_session_duration
      tags                                = local.tags
      inline_policy                       = ""
      customer_managed_policy_attachments = []
      policy_attachments = [
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      ]
    },
    {
      name                                = "ReadOnly"
      description                         = "Provides view-only access to most resources."
      relay_state                         = local.default_relay_state
      session_duration                    = local.default_session_duration
      tags                                = local.tags
      inline_policy                       = ""
      policy_attachments                  = ["arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "GithubAutomation"
      description                         = "GrantsGrants permissions for automation tasks that run on Github Actions."
      relay_state                         = local.default_relay_state
      session_duration                    = local.default_session_duration
      tags                                = local.tags
      inline_policy                       = data.aws_iam_policy_document.github_automation.json
      policy_attachments                  = []
      customer_managed_policy_attachments = []
    },
    {
      name             = "MarketplaceSeller"
      description      = "Grants marketplace access to manage service/product offers."
      relay_state      = local.default_relay_state
      session_duration = local.default_session_duration
      tags             = local.tags
      inline_policy    = data.aws_iam_policy_document.marketplaceseller.json
      policy_attachments = [
        "arn:aws:iam::aws:policy/AWSMarketplaceSellerFullAccess",
        "arn:aws:iam::aws:policy/WellArchitectedConsoleFullAccess",
        "arn:aws:iam::aws:policy/job-function/Billing",
      ]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "DataScientist"
      description                         = "Provides access to AWS services that have to do with Data Science and MLOps."
      relay_state                         = local.default_relay_state
      session_duration                    = "PT2H"
      tags                                = local.tags
      inline_policy                       = data.aws_iam_policy_document.data_scientist.json
      policy_attachments                  = []
      customer_managed_policy_attachments = []
    },
  ]
}
