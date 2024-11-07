module "database_migration_service" {
  source = "github.com/binbashar/terraform-aws-dms?ref=v2.3.0"

  # Subnet group
  repl_subnet_group_name        = "example"
  repl_subnet_group_description = "DMS Subnet group"
  repl_subnet_group_subnet_ids  = ["subnet-1fe3d837", "subnet-129d66ab", "subnet-1211eef5"]

  # DMS Instance
  repl_instance_allocated_storage            = 64
  repl_instance_auto_minor_version_upgrade   = true
  repl_instance_allow_major_version_upgrade  = true
  repl_instance_apply_immediately            = true
  repl_instance_engine_version               = "3.5.2"
  repl_instance_multi_az                     = true
  repl_instance_preferred_maintenance_window = "sun:10:30-sun:14:30"
  repl_instance_publicly_accessible          = false
  repl_instance_class                        = "dms.t3.large"
  repl_instance_id                           = "example"
  repl_instance_vpc_security_group_ids       = ["sg-12345678"]

  endpoints = {
    source_apps_devstg_aurora_pgsql = {
      database_name               = "example"
      endpoint_id                 = "example-source-aurora-pgslq"
      endpoint_type               = "source"
      engine_name                 = "aurora-postgresql"
      extra_connection_attributes = "heartbeatFrequency=1;"
      username                    = "postgresqlUser"
      password                    = "youShouldPickABetterPassword123!"
      port                        = 5432
      server_name                 = "dms-ex-src.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
      ssl_mode                    = "none"
      tags                        = { EndpointType = "source" }
    }

    source_data_science_aurora_mysql = {
      database_name               = "example"
      endpoint_id                 = "example-source-aurora-mysql"
      endpoint_type               = "source"
      engine_name                 = "aurora-mysql"
      extra_connection_attributes = "heartbeatFrequency=1;"
      username                    = "mysqlUser"
      password                    = "passwordsDoNotNeedToMatch789?"
      port                        = 3306
      server_name                 = "dms-ex-src.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
      ssl_mode                    = "none"
      tags                        = { EndpointType = "source" }
    }
  }

  # S3 Endpoints
  s3_endpoints = {
    s3-destination = {
      endpoint_id   = "${local.name}-s3-destination"
      endpoint_type = "destination"
      engine_name   = "s3"
      bucket_folder               = "destinationdata"
      bucket_name                 = module.s3_bucket_datalake.s3_bucket_id
      data_format                 = "parquet"
      ssl_mode                    = "none"
      encryption_mode             = "SSE_S3"
      extra_connection_attributes = ""
      external_table_definition   = file("configs/s3_table_definition.json")
      tags                        = { EndpointType = "s3-source" }
    }
  }

  replication_tasks = {
    cdc_ex = {
      replication_task_id       = "example-cdc"
      migration_type            = "cdc"
      replication_task_settings = file("task_settings.json")
      table_mappings            = file("table_mappings.json")
      source_endpoint_key       = "source"
      target_endpoint_key       = "destination"
      tags                      = { Task = "PostgreSQL-to-MySQL" }
    }
  }

  event_subscriptions = {
    instance = {
      name                             = "instance-events"
      enabled                          = true
      instance_event_subscription_keys = ["example"]
      source_type                      = "replication-instance"
      sns_topic_arn                    = "arn:aws:sns:us-east-1:012345678910:example-topic"
      event_categories                 = [
        "failure",
        "creation",
        "deletion",
        "maintenance",
        "failover",
        "low storage",
        "configuration change"
      ]
    }
    task = {
      name                         = "task-events"
      enabled                      = true
      task_event_subscription_keys = ["cdc_ex"]
      source_type                  = "replication-task"
      sns_topic_arn                = "arn:aws:sns:us-east-1:012345678910:example-topic"
      event_categories             = [
        "failure",
        "state change",
        "creation",
        "deletion",
        "configuration change"
      ]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}