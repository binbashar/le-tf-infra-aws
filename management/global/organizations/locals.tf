locals {
  organizational_units = {
    #
    # Security Organizational Unit Policies
    #
    security = {
      policy = aws_organizations_policy.default
    },
    #
    # Shared Organizational Unit Policies
    #
    shared = {
      policy = aws_organizations_policy.standard
    },
    #
    # Networks Organizational Unit Policies
    #
    network = {
      policy = aws_organizations_policy.default
    },
    #
    # Apps DevStg: Organizational Unit Policies
    #
    bbl_apps_devstg = {
      policy = aws_organizations_policy.standard
    },
    #
    # Apps Prd: Organizational Unit Policies
    #
    bbl_apps_prd = {
      policy = aws_organizations_policy.standard
    }
    #
    # Data Science: Organizational Unit Policies
    #
    bbl_data_science = {
      policy = aws_organizations_policy.standard
    }
  }

  root_account = {
    email = "aws+root@binbash.com.ar"
  }

  #
  # Accounts configurations
  #
  accounts = {
    #
    # Security: this is for centralized security access account that we can use to grant
    # permissions over the other accounts.
    #
    security = {
      email     = "aws+security@binbash.com.ar",
      parent_ou = "security"
    },
    #
    # Shared: this account will be used to host shared resources that are consumed
    # or provide services to the other accounts. This is for shared resources -- although another option could be to
    # have a shared account per business unit (e.g. project, and others)
    #
    shared = {
      email     = "aws+shared@binbash.com.ar",
      parent_ou = "shared"
    },
    #
    # Network: this account will be used to host network resources that are consumed
    #  or provide services to the other accounts.
    #
    network = {
      email     = "aws+network@binbash.com.ar",
      parent_ou = "network"
    },
    #
    # Project DevStg: services and resources related to development/stage are
    #  placed and maintained here.
    #
    apps-devstg = {
      email     = "aws+apps-devstg@binbash.com.ar",
      parent_ou = "bbl_apps_devstg"
    },
    #
    # Project Prd: services and resources related to production are placed and
    #  maintained here.
    #
    apps-prd = {
      email     = "aws+apps-prd@binbash.com.ar",
      parent_ou = "bbl_apps_prd"
    }
    #
    # DataScience: data science workloads, MLOps, and such.
    #
    data-science = {
      email     = "aws+data-science@binbash.com.ar",
      parent_ou = "bbl_data_science"
    }
  }

  ## Delegated services to Security Account
  delegated_services = [
    "access-analyzer.amazonaws.com",
    "config.amazonaws.com"
  ]
}
