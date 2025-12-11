#=============================#
# Amazon MWAA Environment     #
#=============================#
module "mwaa" {
  source  = "aws-ia/mwaa/aws"
  version = "0.0.6"

  # Basic Configuration
  name              = local.mwaa_name
  airflow_version   = var.airflow_version
  environment_class = var.environment_class

  # Networking
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  # Worker Configuration
  min_workers = var.min_workers
  max_workers = var.max_workers
  schedulers  = var.schedulers

  # Webserver Access
  webserver_access_mode = var.webserver_access_mode

  # S3 Configuration
  create_s3_bucket   = true
  source_bucket_name = local.s3_bucket_name
  dag_s3_path        = var.dag_s3_path

  # Optional: Requirements and Plugins
  # requirements_s3_path = var.requirements_s3_path
  # plugins_s3_path      = var.plugins_s3_path

  # IAM Configuration
  create_iam_role = true
  iam_role_name   = "${local.mwaa_name}-execution-role"

  # Security Group Configuration
  create_security_group = true

  # Airflow Configuration Options
  airflow_configuration_options = {
    "core.load_default_connections" = "false"
    "core.load_examples"            = "false"
    "webserver.dag_default_view"    = "tree"
    "webserver.dag_orientation"     = "TB"
    "logging.logging_level"         = var.log_level
  }

  # Logging Configuration
  logging_configuration = var.enable_logging ? {
    dag_processing_logs = {
      enabled   = true
      log_level = var.log_level
    }

    scheduler_logs = {
      enabled   = true
      log_level = var.log_level
    }

    task_logs = {
      enabled   = true
      log_level = var.log_level
    }

    webserver_logs = {
      enabled   = true
      log_level = var.log_level
    }

    worker_logs = {
      enabled   = true
      log_level = var.log_level
    }
  } : null

  # Tags
  tags = merge(
    local.tags,
    {
      Name = local.mwaa_name
    }
  )
}
