resource "null_resource" "cluster_mode" {
  lifecycle {
    precondition {
      condition     = var.cluster_mode_enabled != var.single_instance_mode_enabled
      error_message = "Validation failed: 'cluster_mode_enabled' and 'single_instance_mode_enabled' must be different. Cannot be both '${var.cluster_mode_enabled}'"
    }
  }
}


resource "null_resource" "multi_az_and_failover" {
  lifecycle {
    precondition {
      condition     = !(var.multi_az_enabled && !var.automatic_failover_enabled)
      error_message = "Validation failed: 'If want to enable Multi-AZ, must set 'automatic_failover_enabled' to true.'"
    }
  }
}

resource "null_resource" "cluster_mode_and_failover" {
  lifecycle {
    precondition {
      condition     = !(var.cluster_mode_enabled && !var.automatic_failover_enabled)
      error_message = "Validation failed: 'If cluster_mode_enabled is true, automatic_failover_enabled must also be true.'"
    }
  }
}
