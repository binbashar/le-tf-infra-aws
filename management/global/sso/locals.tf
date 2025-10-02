locals {
  #----------------------------------------------------------------------------
  # Define the users here
  #----------------------------------------------------------------------------
  users = {
    # Binbash
    "diego.ojeda" = {
      first_name = "Diego"
      last_name  = "Ojeda"
      email      = "diego.ojeda@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
      ]
    }
    "exequiel.barrirero" = {
      first_name = "Exequiel"
      last_name  = "Barrirero"
      email      = "exequiel.barrirero@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
        "datascientists",
        "marketplaceseller",
      ]
    }
    "marcos.pagnucco" = {
      first_name = "Marcos"
      last_name  = "Pagnucco"
      email      = "marcos.pagnucco@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
        "readonly",
      ]
    }
    "franco.gauchat" = {
      first_name = "Franco"
      last_name  = "Gauchat"
      email      = "franco.gauchat@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "hecber.cordova" = {
      first_name = "Hecber"
      last_name  = "Cordova"
      email      = "hecber.cordova@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "francisco.rivera" = {
      first_name = "Francisco"
      last_name  = "Rivera"
      email      = "francisco.rivera@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
      ]
    }
    "emiliano.brest" = {
      first_name = "Emiliano"
      last_name  = "Brest"
      email      = "emiliano.brest@binbash.com.ar"
      groups = [
        "marketplaceseller",
      ]
    }
    "juan.delacamara" = {
      first_name = "Juan"
      last_name  = "de la Camara"
      email      = "juan.delacamara@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "angelo.fenoglio" = {
      first_name = "Angelo"
      last_name  = "Fenoglio"
      email      = "angelo.fenoglio@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
      ]
    }
    "jose.peinado" = {
      first_name = "Jose"
      last_name  = "Peinado"
      email      = "jose.peinado@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "luis.gallardo" = {
      first_name = "Luis"
      last_name  = "Gallardo"
      email      = "luis.gallardo@binbash.com.ar"
      groups = [
        "devops",
        "administrators",
      ]
    }
    "ezequiel.godoy" = {
      first_name = "Ezequiel"
      last_name  = "Godoy"
      email      = "ezequiel.godoy@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
      ]
    }
    "matias.rodriguez" = {
      first_name = "Matias"
      last_name  = "Rodriguez"
      email      = "matias.rodriguez@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
        "datascientists",
        "readonly",
      ]
    }
    "martin.galeano" = {
      first_name = "Martin"
      last_name  = "Galeano"
      email      = "martin.galeano@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
      ]
    }
    "caetano.prates" = {
      first_name = "Caetano"
      last_name  = "Prates"
      email      = "caetano.prates@binbash.com.ar"
      groups = [
        "marketplaceseller",
      ]
    }
    "matias.sorozabal" = {
      first_name = "Matias"
      last_name  = "Sorozabal"
      email      = "matias.sorozabal@binbash.com.ar"
      groups = [
        "datascientists",
      ]
    }
    "ignacio.gomez" = {
      first_name = "Ignacio"
      last_name  = "Gomez"
      email      = "ignacio.gomez@binbash.com.ar"
      groups = [
        "datascientists",
      ]
    }
    "juan.delatorre" = {
      first_name = "Juan"
      last_name  = "De la Torre"
      email      = "juan.delatorre@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "marcelo.beresvil" = {
      first_name = "Marcelo"
      last_name  = "Beresvil"
      email      = "marcelo.beresvil@binbash.com.ar"
      groups = [
        "marketplaceseller",
      ]
    }
    "rene.montilva" = {
      first_name = "Rene"
      last_name  = "Montilva"
      email      = "rene.montilva@binbash.com.ar"
      groups = [
        "administrators",
        "devops",
      ]
    }
    "manuel.quinteros" = {
      first_name = "Manuel"
      last_name  = "Quinteros"
      email      = "manuel.quinteros@binbash.com.ar"
      groups = [
        "devops",
        "marketplaceseller",
      ]
    }
    "julian.curetti" = {
      first_name = "Julian"
      last_name  = "Curetti"
      email      = "julian.curetti@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "ariel.jalil" = {
      first_name = "Ariel"
      last_name  = "Jalil"
      email      = "ariel.jalil@binbash.com.ar",
      groups = [
        "devops",
      ]
    }
    "dario.villavicencio" = {
      first_name = "Dario"
      last_name  = "Villavicencio"
      email      = "dario.villavicencio@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "alex.delossantos" = {
      first_name = "Alex"
      last_name  = "DelosSantos"
      email      = "alex.delossantos@binbash.com.ar"
      groups = [
        "datascientists",
        "administrators"
      ]
    }
    "favio.tolosa" = {
      first_name = "Favio"
      last_name  = "Tolosa"
      email      = "favio.tolosa@binbash.com.ar"
      groups = [
        "devops",
      ]
    }
    "santiago.respane" = {
      first_name = "Santiago"
      last_name  = "Respane"
      email      = "santiago.respane@binbash.com.ar"
      groups = [
        "datascientists",
        "devops"
      ]
    }
    "lucas.langwagen" = {
      first_name = "Lucas"
      last_name  = "Langwagen"
      email      = "lucas.langwagen@binbash.com.ar"
      groups = [
        "datascientists",
      ]
    }
    "diego.maye" = {
      first_name = "Diego"
      last_name  = "Maye"
      email      = "diego.maye@binbash.com.ar"
      groups = [
        "datascientists",
      ]
    }
    "roberto.trujillo" = {
      first_name = "Roberto"
      last_name  = "Trujillo"
      email      = "roberto.trujillo@binbash.com.ar"
      groups = [
        "datascientists"
      ]
    }
    "marcelo.rodriguez" = {
      first_name = "Marcelo"
      last_name  = "Rodriguez"
      email      = "marcelo.rodriguez@binbash.com.ar"
      groups = [
        "datascientists"
      ]
    }
    "hernan.rezilo" = {
      first_name = "Hernan"
      last_name  = "Rezilo"
      email      = "hernan.rezilo@binbash.com.ar"
      groups = [
        "devops"
      ]
    }
  }

  #----------------------------------------------------------------------------
  # Define the groups here
  #----------------------------------------------------------------------------
  groups = {
    administrators = {
      name        = "Administrators"
      description = "Provides full access to AWS services and resources."
    }
    devops = {
      name        = "DevOps"
      description = "Provides full access to many AWS services and resources except billing."
    }
    finops = {
      name        = "FinOps"
      description = "Provides access to billing and cost management."
    }
    securityauditor = {
      name        = "SecurityAuditor"
      description = "Provides access for security auditing."
    }
    readonly = {
      name        = "ReadOnly"
      description = "Provides view-only access to most resources."
    }
    marketplaceseller = {
      name        = "MarketplaceSeller"
      description = "Provides access to the AWS MarketPlace Seller."
    }
    datascientists = {
      name        = "DataScientists"
      description = "Provides access to the Data Science related services."
    }
  }

  #----------------------------------------------------------------------------
  # Define user and group membership
  #----------------------------------------------------------------------------
  # Get only users and groups, discard the rest
  extract_users_groups_only = {
    for user, user_data in local.users : user => user_data.groups
  }

  # Get a list of maps that combine every user with every group they belong to
  users_groups_combined = [
    for user, groups in local.extract_users_groups_only : {
      for group in groups :
      "${user}_${group}" => {
        "user"  = user
        "group" = group
      }
    }
  ]

  # Now get all the submaps in the list merged into a single map that can be iterated more easily
  users_groups_membership = zipmap(
    flatten(
      [for item in local.users_groups_combined : keys(item)]
    ),
    flatten(
      [for item in local.users_groups_combined : values(item)]
    )
  )

  #----------------------------------------------------------------------------
  # IAM Identity Center
  #----------------------------------------------------------------------------
  # This identifies the SSO instance we'll be working with
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  # Principal types
  principal_type_group = "GROUP"
  principal_type_user  = "USER"

  # The duration needs to be specified in ISO 8601. The minimum session duration
  # is 1 hour, and can be set to a maximum of 12 hours.
  # Ref: https://docs.aws.amazon.com/singlesignon/latest/userguide/howtosessionduration.html
  #
  # You can find some examples below:
  #  - PT12H    Twelve hours
  #  - PT2H30M  Two hours and thirty minutes
  #  - PT90M    Ninety minutes
  #
  default_session_duration = "PT1H"

  default_relay_state = ""

  #----------------------------------------------------------------------------
  # AWS Client VPN
  #----------------------------------------------------------------------------
  enable_sso_client_vpn = true

  client_vpn_groups = [
    "devops"
  ]

  #----------------------------------------------------------------------------
  # Misc
  #----------------------------------------------------------------------------

  tags = {
    Terraform = "true"
    Layer     = local.layer_name
  }
}
