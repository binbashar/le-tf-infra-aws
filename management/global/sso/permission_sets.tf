module "permission_sets" {
  source = "github.com/binbashar/terraform-aws-sso.git//modules/permission-sets?ref=0.6.1"

  permission_sets = [
    {
      name               = "Administrator",
      description        = "Grants full access to AWS services and resources.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    },
    {
      name               = "DevOps",
      description        = "Grants permissions for managing most resources except billing.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = data.aws_iam_policy_document.devops.json,
      policy_attachments = []
    },
    {
      name               = "FinOps",
      description        = "Grants permissions for billing and cost management.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/job-function/Billing"]
    },
    {
      name               = "SecurityAuditor",
      description        = "Grants permissions for security auditing.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/SecurityAudit"]
    },
    {
      name               = "ReadOnly",
      description        = "Grants read-only permissions.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
    },
    {
      name               = "GithubAutomation",
      description        = "GrantsGrants permissions for automation tasks that run on Github Actions.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = data.aws_iam_policy_document.github_automation.json,
      policy_attachments = []
    }
  ]
}
