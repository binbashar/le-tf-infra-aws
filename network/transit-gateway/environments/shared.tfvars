#===========================================#
# Transit Gateway Configuration - Shared Environment
#===========================================#

tgw_config = {
  version          = "1.0.0"
  region           = "us-east-1"
  region_secondary = null

  metadata = {
    name        = "bb-network-tgw"
    environment = "network"
    tags = {
      Environment = "network"
      Layer       = "transit-gateway"
      Terraform   = "true"
    }
  }

  connection = {
    create          = true
    existing_tgw_id = null
    accounts = {
      network     = true
      shared      = true
      apps-devstg = false
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
        create = true
      }
      apps-devstg = {
        create = false
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
      enabled = true
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

