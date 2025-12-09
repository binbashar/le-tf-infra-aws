#===========================================#
# Transit Gateway Configuration - DevStg Environment
#===========================================#

tgw_config = {
  version          = "1.0.0"
  region           = "us-east-1"
  region_secondary = null

  metadata = {
    name        = "bb-apps-devstg-tgw"
    environment = "apps-devstg"
    tags = {
      Environment = "apps-devstg"
      Layer       = "transit-gateway"
      Terraform   = "true"
    }
  }

  connection = {
    create          = true
    existing_tgw_id = null
    accounts = {
      network     = false
      shared      = false
      apps-devstg = true
      apps-prd    = false
    }
    vpc_attachments = {}
  }

  networking = {
    route_tables = {
      default = {
        create = true
      }
      inspection = {
        create = false
      }
      apps-devstg = {
        create = true
      }
      apps-prd = {
        create = false
      }
    }
    blackhole_routes = []
  }

  security = {
    ram_sharing = {
      enabled    = true
      principals = []
    }
    network_firewall = {
      enabled = false
    }
  }

  high_availability = {
    multi_region = {
      enabled     = false
      peer_region = null
    }
  }

  monitoring = {
    enabled = false
  }

  logging = {
    enabled = false
  }

  compliance = {
    tags = {}
  }

  automation = {
    auto_accept_attachments = false
    auto_propagate_routes   = false
  }
}

