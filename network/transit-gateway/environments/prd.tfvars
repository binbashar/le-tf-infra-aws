#===========================================#
# Transit Gateway Configuration - Production Environment
#===========================================#

tgw_config = {
  version          = "1.0.0"
  region           = "us-east-1"
  region_secondary = "us-east-2"

  metadata = {
    name        = "bb-apps-prd-tgw"
    environment = "apps-prd"
    tags = {
      Environment = "apps-prd"
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
      apps-devstg = false
      apps-prd    = true
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
        create = false
      }
      apps-prd = {
        create = true
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
      enabled     = true
      peer_region = "us-east-2"
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

