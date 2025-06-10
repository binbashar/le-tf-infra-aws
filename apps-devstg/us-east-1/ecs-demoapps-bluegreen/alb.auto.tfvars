# Application Load Balancer (ALB) Configuration
# This configuration defines the settings for the ALB that will distribute traffic to the ECS services
alb_settings = {
  # Basic ALB Configuration
  name                       = "ecs-bluegreen-alb"                                      # Name of the load balancer
  load_balancer_type         = "application"                                            # Type of load balancer (application for HTTP/HTTPS)
  internal                   = true                                                     # Whether the ALB is internal (not internet-facing)
  enable_deletion_protection = true                                                     # Prevents accidental deletion of the ALB

  # Ingress Rules Configuration
  # Defines which traffic is allowed to reach the ALB
  security_group_ingress_rules = {
    http = {
      from_port = 80 # Allow HTTP traffic on port 80
      to_port   = 80
      protocol  = "tcp"
      cidr_ipv4 = "0.0.0.0/0" # Allow from any IP (consider restricting in production)
    }
    http_8080 = {
      from_port = 8080 # Allow HTTP traffic on port 8080
      to_port   = 8080
      protocol  = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
    }
    https = {
      from_port = 443 # Allow HTTPS traffic on port 443
      to_port   = 443
      protocol  = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }

  # Egress Rules Configuration
  # Defines which traffic the ALB can send out
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"        # Allow all protocols
      cidr_ipv4   = "0.0.0.0/0" # Allow to any destination
    }
  }

  # Listener Configuration
  # Defines how the ALB handles incoming traffic
  listeners = {
    # Main HTTP listener for the backend services
    http = {
      port     = 8080   # Port the listener will listen on
      protocol = "HTTP" # Protocol to use
      # Default action when no rules match
      fixed_response = {
        content_type = "text/plain" # Response content type
        message_body = "Not Found"  # Response message
        status_code  = "404"        # HTTP status code
      }
    }
    # Test HTTP listener for testing purposes
    http_test = {
      port     = 8081 # Separate port for test traffic
      protocol = "HTTP"
      # Default action when no rules match
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }

  # Resource Tags
  # Used for resource organization and cost allocation
  tags = {
    Environment = "dev"           # Environment tag (dev, staging, prod)
    Project     = "ecs-bluegreen" # Project identifier
  }
}
