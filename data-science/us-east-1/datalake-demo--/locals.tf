locals {
  region = "us-east-1"
  name   = "${var.project}-${var.environment}-data-lake-demo"

  # vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  db_name     = "example"
  db_username = "example"
  db_password = "password123!" # do better!

  # MSK
  # sasl_scram_credentials = {
  #   username = local.name
  #   password = "password123!" # do better!
  # }

  # aws dms describe-event-categories
  replication_instance_event_categories = ["failure", "creation", "deletion", "maintenance", "failover", "low storage", "configuration change"]
  replication_task_event_categories     = ["failure", "state change", "creation", "deletion", "configuration change"]

  tags = {
    Name       = local.name
    Terraform          = "true"
    Environment        = var.environment
  }
}
