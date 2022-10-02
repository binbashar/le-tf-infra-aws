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
    #
    # Demo: Google Microservices
    #
    demo-google-microservices-adservice = {
      create            = true
      name              = "demo-google-microservices-adservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-cartservice = {
      create            = true
      name              = "demo-google-microservices-cartservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-checkoutservice = {
      create            = true
      name              = "demo-google-microservices-checkoutservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-currencyservice = {
      create            = true
      name              = "demo-google-microservices-currencyservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-emailservice = {
      create            = true
      name              = "demo-google-microservices-emailservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-frontend = {
      create            = true
      name              = "demo-google-microservices-frontend"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-paymentservice = {
      create            = true
      name              = "demo-google-microservices-paymentservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-productcatalogservice = {
      create            = true
      name              = "demo-google-microservices-productcatalogservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-recommendationservice = {
      create            = true
      name              = "demo-google-microservices-recommendationservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-shippingservice = {
      create            = true
      name              = "demo-google-microservices-shippingservice"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-loadgenerator = {
      create            = true
      name              = "demo-google-microservices-loadgenerator"
      read_permissions  = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      write_permissions = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
