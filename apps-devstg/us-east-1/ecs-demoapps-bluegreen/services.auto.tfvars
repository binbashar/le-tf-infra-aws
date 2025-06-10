#   Backend Services Configuration Details   #
##############################################

# Main services map that defines all ECS services to be deployed
services = {
  # Simple Service Configuration
  # This service runs a basic nginx container for demonstration purposes
  "emojivoto-web" = {
    # Basic service configuration
    name                           = "emojivoto-web" # Name of the ECS service
    ignore_task_definition_changes = true            # Whether to ignore task definition changes
    ecr_repository                 = "emojivoto-web" # ECR repository name for the container image
    git_repository = {
      name   = "github.com/binbashar/le-emojivoto/" # Git repository name for CI/CD
      branch = "master"                             # Branch to use for deployments
    }
    alarms = {} # CloudWatch alarms configuration (empty for this example)

    # Deployment configuration
    deployment_controller = {
      type = "CODE_DEPLOY" # Uses AWS CodeDeploy for blue/green deployments
    }

    # Auto-scaling configuration
    autoscaling_configuration = {
      enable       = true # Enable auto-scaling
      min_capacity = 1    # Minimum number of tasks
      max_capacity = 1    # Maximum number of tasks
    }

    # IAM role configuration for the task
    task_iam_role_name = "ecs-bluegreen-service-task-role" # IAM role name for the task
    tasks_iam_role_statements = [
      {
        effect = "Allow"
        actions = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        resources = ["*"] # SQS permissions for the task
      }
    ]
    create_task_definition  = true                              # Whether to create a new task definition
    task_exec_iam_role_name = "ecs-bluegreen-service-task-exec" # IAM role for task execution
    task_exec_secret_arns = [
      "arn:aws:secretsmanager:us-east-1:*:secret:*"
    ]

    task_exec_iam_statements = [
      {
        effect = "Allow"
        actions = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        resources = ["*"] # KMS permissions for task execution
      }
    ]

    # Application configuration
    application_port     = 80     # Port the application listens on
    application_protocol = "HTTP" # Protocol used by the application
    application_health_check = {
      path                = "/"    # Health check endpoint
      interval            = 30     # Health check interval in seconds
      timeout             = 20     # Health check timeout in seconds
      healthy_threshold   = 2      # Number of successful checks to mark healthy
      unhealthy_threshold = 4      # Number of failed checks to mark unhealthy
      port                = 80     # Port for health checks
      protocol            = "HTTP" # Protocol for health checks
    }

    # Container configuration
    container_definitions = {
      simple-service = {
        cpu                      = 256                                     # CPU units (256 = 0.25 vCPU)
        memory                   = 512                                     # Memory in MB
        image                    = "docker.l5d.io/buoyantio/emojivoto-web" # Container image to use
        readonly_root_filesystem = false                                   # Whether the container has read-only root filesystem
        port_mappings = [
          {
            name          = "emojivoto-service" # Name of the port mapping
            containerPort = 80                  # Port inside the container
            hostPort      = 80                  # Port on the host
            protocol      = "tcp"               # Protocol to use
          }
        ]
        environment = [
          {
            name  = "FAKE_ENV_VAR" # Environment variable name
            value = "fake-value"   # Environment variable value
          }
        ]
        cloudwatch_log_group_retention_in_days = 3 # How long to retain logs
      }
    }
    tags         = {} # Resource tags
    service_tags = {} # Service-specific tags
  }
}

# Security Group Configuration
# Defines network access rules for the services
security_settings = {
  vpc_id              = "vpc-072f329fed6757e95"               # VPC ID where services will run
  security_group_name = "backend"                             # Name of the security group
  description         = "Security Group for Backend Services" # Security group description
  security_group_rules = [
    "http-80-tcp",   # Allow HTTP traffic on port 80
    "http-8080-tcp", # Allow HTTP traffic on port 8080
    "https-443-tcp", # Allow HTTPS traffic on port 443
    "https-8443-tcp" # Allow HTTPS traffic on port 8443
  ]
}

# Schedule Configuration
# Controls when services are turned on/off to save costs
turn_off_services = false # Whether to enable scheduled start/stop
turn_off_on_services_schedule = {
  schedule_off_expression = "cron(0 23 ? * MON,TUE,WED,THUR,FRI *)" # Turn off at 11 PM on weekdays
  schedule_on_expression  = "cron(0 0 ? * MON,TUE,WED,THUR,FRI *)"  # Turn on at midnight on weekdays
}
