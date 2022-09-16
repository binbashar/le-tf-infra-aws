locals {
  default_lifecycle_policy_rules = [
    module.ecr_lifecycle_rule_default_policy_bycount.policy_rule,
  ]

  #
  # List of repositories to create and their attributes
  #
  repository_list = {
    weaveworksdemos_user = {
      create            = true
      name              = "weaveworksdemos/user"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_userdb = {
      create            = true
      name              = "weaveworksdemos/user-db"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_shipping = {
      create            = true
      name              = "weaveworksdemos/shipping"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_queuemaster = {
      create            = true
      name              = "weaveworksdemos/queue-master"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_payment = {
      create            = true
      name              = "weaveworksdemos/payment"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_orders = {
      create            = true
      name              = "weaveworksdemos/orders"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_frontend = {
      create            = true
      name              = "weaveworksdemos/front-end"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_catalogue = {
      create            = true
      name              = "weaveworksdemos/catalogue"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_cataloguedb = {
      create            = true
      name              = "weaveworksdemos/catalogue-db"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_carts = {
      create            = true
      name              = "weaveworksdemos/carts"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-apps_web = {
      create            = true
      name              = "demo-apps/web"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-apps_voting-svc = {
      create            = true
      name              = "demo-apps/voting-svc"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-apps_emoji-svc = {
      create            = true
      name              = "demo-apps/emoji-svc"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

}
