module "permission_sets" {
  source = "github.com/binbashar/terraform-aws-sso.git//modules/permission-sets?ref=0.6.1"

  enabled = true
  permission_sets = [
    {
      name               = "Admins",
      description        = "Grants full access to AWS services and resources.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    },
    {
      name               = "SysAdmins",
      description        = "Grants full access permissions necessary for resources required for application and development operations.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/job-function/SystemAdministrator"]
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
      name               = "SecurityAuditors",
      description        = "Grants permissions for security auditing.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/SecurityAudit"]
    },
    {
      name               = "Guests",
      description        = "Grants permissions for read-only guests.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = "",
      policy_attachments = ["arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
    },
    {
      name               = "Automation",
      description        = "Grants permissions for build, deployment and other automation tasks.",
      relay_state        = "",
      session_duration   = local.session_duration,
      tags               = local.tags,
      inline_policy      = data.aws_iam_policy_document.DeployMaster.json,
      policy_attachments = []
    }
  ]
}
