#=============================#
# EventBridge Scheduler Config#
#=============================#

# Create IAM role for EventBridge Scheduler
create_scheduler_role = true

# Define scheduled triggers for creating MWAA environments using EventBridge Scheduler
schedules = {
  # Example: Create a new MWAA environment on-demand
  create-scheduled-env = {
    description         = "Create new MWAA environment for scheduled workloads"
    schedule_expression = "cron(55 16 * * ? *)" # Daily at 16:55 America/Argentina/Buenos_Aires (UTC-3)
    dag_s3_path         = "dags/"
    # execution_role_arn will use the role created in iam.tf by default
    source_bucket_arn = "arn:aws:s3:::bb-apache-airflow-dag"
    subnet_ids = [
      "subnet-0ae4e4874034d9346",
      "subnet-0879ec2972f28cc03"
    ]
    security_group_ids = [
      "sg-0cf750d7e66461353"
    ]
    environment_class     = "mw1.small"
    airflow_version       = "2.10.1"
    max_workers           = 10
    min_workers           = 1
    schedulers            = 2
    webserver_access_mode = "PRIVATE_ONLY"
    airflow_configuration_options = {
      "core.load_examples"     = "false"
      "logging.logging_level"  = "INFO"
      "secrets.backend"        = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
      "secrets.backend_kwargs" = "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\"}"
    }
    enabled  = true
    timezone = "America/Argentina/Buenos_Aires"
    flexible_time_window = {
      mode                      = "FLEXIBLE"
      maximum_window_in_minutes = 5
    }
  }

  # # Example: Create environment with flexible time window
  # create-flexible-env = {
  #   description         = "Create MWAA environment with flexible scheduling"
  #   schedule_expression = "rate(7 days)" # Weekly
  #   dag_s3_path         = "dags/"
  #   # execution_role_arn will use the role created in iam.tf by default
  #   source_bucket_arn   = "arn:aws:s3:::bb-apache-airflow-dag"
  #   subnet_ids = [
  #     "subnet-0ae4e4874034d9346",
  #     "subnet-0879ec2972f28cc03"
  #   ]
  #   security_group_ids = [
  #     "sg-0cf750d7e66461353"
  #   ]
  #   environment_class     = "mw1.medium"
  #   airflow_version       = "2.10.1"
  #   max_workers           = 25
  #   min_workers           = 2
  #   schedulers            = 3
  #   webserver_access_mode = "PRIVATE_ONLY"
  #   weekly_maintenance_window_start = "MON:03:00"
  #   airflow_configuration_options = {
  #     "core.load_examples"        = "false"
  #     "logging.logging_level"     = "WARNING"
  #     "webserver.dag_default_view" = "tree"
  #   }
  #   enabled  = false
  #   timezone = "America/New_York"
  #   flexible_time_window = {
  #     mode                      = "FLEXIBLE"
  #     maximum_window_in_minutes = 60
  #   }
  # }
}
