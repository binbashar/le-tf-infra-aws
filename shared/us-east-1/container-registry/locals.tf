locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  #
  # Repositories to create and their attributes
  #
  repositories = {
    weaveworksdemos_user = {
      name                   = "weaveworksdemos/user"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_userdb = {
      name                   = "weaveworksdemos/user-db"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_shipping = {
      name                   = "weaveworksdemos/shipping"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_queuemaster = {
      name                   = "weaveworksdemos/queue-master"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_payment = {
      name                   = "weaveworksdemos/payment"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_orders = {
      name                   = "weaveworksdemos/orders"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_frontend = {
      name                   = "weaveworksdemos/front-end"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_catalogue = {
      name                   = "weaveworksdemos/catalogue"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_cataloguedb = {
      name                   = "weaveworksdemos/catalogue-db"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    weaveworksdemos_carts = {
      name                   = "weaveworksdemos/carts"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-apps_web = {
      name                   = "demo-apps/web"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-apps_voting-svc = {
      name                   = "demo-apps/voting-svc"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-apps_emoji-svc = {
      name                   = "demo-apps/emoji-svc"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    #
    # Demo: Google Microservices
    #
    demo-google-microservices-adservice = {
      name                   = "demo-google-microservices-adservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-cartservice = {
      name                   = "demo-google-microservices-cartservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-checkoutservice = {
      name                   = "demo-google-microservices-checkoutservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-currencyservice = {
      name                   = "demo-google-microservices-currencyservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-emailservice = {
      name                   = "demo-google-microservices-emailservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-frontend = {
      name                   = "demo-google-microservices-frontend"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-paymentservice = {
      name                   = "demo-google-microservices-paymentservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-productcatalogservice = {
      name                   = "demo-google-microservices-productcatalogservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-recommendationservice = {
      name                   = "demo-google-microservices-recommendationservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-shippingservice = {
      name                   = "demo-google-microservices-shippingservice"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    demo-google-microservices-loadgenerator = {
      name                   = "demo-google-microservices-loadgenerator"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    #
    # Demo: emojivoto
    #
    emojivoto-emoji-svc = {
      name                   = "emojivoto-emoji-svc"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    emojivoto-voting-svc = {
      name                   = "emojivoto-voting-svc"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    emojivoto-web = {
      name                   = "emojivoto-web"
      read_access_arns       = ["arn:aws:iam::${var.accounts.apps-devstg.id}:root"]
      read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_caller_identity" "current" {}
