#
# ConfigMap used to manage permissions granted through aws-iam-authenticator
#
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = merge(
      {
        # "app.kubernetes.io/name"       = "aws-auth"
        # "app.kubernetes.io/version"    = "1.0.0"
        "app.kubernetes.io/component" = "aws-iam-authenticator"
      },
      local.labels
    )
  }

  data = {
    # -----------------------------------------------------------------------
    # You can grant permissions by role
    # -----------------------------------------------------------------------
    mapRoles = yamlencode([
      # {
      #   rolearn  = "arn:aws:iam::523857393444:role/DeployMaster"
      #   username = "DeployMaster"
      #   groups   = ["system:masters"]
      # },
    ])

    # -----------------------------------------------------------------------
    # You can also grant permissions to specific users
    # -----------------------------------------------------------------------
    mapUsers = yamlencode([
      # {
      #   userarn  = "arn:aws:iam:[ACCOUNT]:user/john.doe"
      #   username = "john.doe"
      #   groups   = ["system:masters"]
      # }
    ])

    # -----------------------------------------------------------------------
    # Or you can grant permissions to AWS accounts
    # -----------------------------------------------------------------------
    mapAccounts = yamlencode([
      # "900980591242", # security
      # "763606934258", # shared
      # "523857393444", # apps-devstg
    ])
  }
}
