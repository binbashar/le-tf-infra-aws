# Deployment Configuration
# This configuration defines how applications are deployed using AWS CodeDeploy and CodePipeline
deployment_settings = {
  # Path to the task definition template used for ECS deployments
  task_definition_template_path = "task-definition-template.json"
  image_tag_prefix = "app-devstg"

  # Source code repository configuration
  source_action = {
    name = "GitHub" # Source code repository provider
  }

  # Traffic Routing Configuration
  # Controls how traffic is shifted during deployments
  traffic_routing_config = {
    type       = "AllAtOnce" # Deploy to all instances simultaneously
    interval   = 1           # Time interval between traffic shifts (in minutes)
    percentage = 100         # Percentage of traffic to shift at once
  }

  # Deployment Style Configuration
  # Defines the deployment strategy and traffic control
  deployment_style = {
    deployment_option = "WITH_TRAFFIC_CONTROL" # Enable traffic shifting during deployment
    deployment_type   = "BLUE_GREEN"           # Use blue/green deployment strategy
  }

  # Minimum Healthy Hosts Configuration
  # Ensures a minimum number of healthy instances during deployment
  minimum_healthy_hosts = {
    type  = "HOST_COUNT" # Use absolute count instead of percentage
    value = 1            # Minimum number of healthy hosts required
  }

  # Blue/Green Deployment Configuration
  # Controls how the blue/green deployment process works
  blue_green_deployment_config = {
    # Configuration for handling old (blue) instances after successful deployment
    terminate_blue_instances_on_deployment_success = {
      action                           = "TERMINATE" # Action to take on old instances
      termination_wait_time_in_minutes = 4           # Wait time before terminating old instances
    }
    # Configuration for handling deployment timeouts
    deployment_ready_option = {
      action_on_timeout = "CONTINUE_DEPLOYMENT" # Continue deployment if timeout occurs
    }
  }

  # Production Traffic Route Configuration
  # Specifies which ALB listener to use for production traffic
  prod_traffic_route_listener_name = "http" # Listener name in ALB configuration

  # S3 Bucket Configuration for CodePipeline
  # Defines the storage location for pipeline artifacts and deployment files
  bucket = {
    name                    = "ecs-bluegreen-codepipeline" # Name of the S3 bucket
    force_destroy           = false                        # Prevent accidental bucket deletion
    attach_policy           = false                        # Don't attach additional policies
    block_public_acls       = true                         # Block public ACLs
    block_public_policy     = true                         # Block public bucket policies
    restrict_public_buckets = true                         # Restrict public bucket access
    versioning = {
      status     = true  # Enable versioning
      mfa_delete = false # Don't require MFA for deletion
    }
    kms_master_key_id = "alias/aws/s3" # Use AWS managed KMS key
    sse_algorithm     = "AES256"       # Server-side encryption algorithm

    # Lifecycle Rules Configuration
    # Automatically manage object lifecycle in the bucket
    lifecycle_rule = [
      {
        # Rule for report files
        id      = "delete-reports-1-day"
        enabled = true
        filter = {
          prefix = "reports/" # Apply to objects in reports/ directory
        }
        noncurrent_version_expiration = {
          days = 1 # Delete non-current versions after 1 day
        }
        expiration = {
          days = 1 # Delete current versions after 1 day
        }
      },
      {
        # Rule for print files
        id      = "delete-prints-1-day"
        enabled = true
        filter = {
          prefix = "prints/" # Apply to objects in prints/ directory
        }
        noncurrent_version_expiration = {
          days = 1 # Delete non-current versions after 1 day
        }
        expiration = {
          days = 1 # Delete current versions after 1 day
        }
      }
    ]
  }

  # SNS Notification Configuration
  # Defines how deployment notifications are sent
  notification = {
    name                        = "codepipeline-notifications" # Name of the SNS topic
    create_topic_policy         = true                         # Create SNS topic policy
    enable_default_topic_policy = false                        # Don't use default SNS policy
  }
}

# Git Service Configuration
# Defines the Git service configuration for CodePipeline
git_service = {
  connection_name = "github" # Name of the Git service connection
  type            = "GitHub" # Type of Git service (github, gitlab, etc.)
}

