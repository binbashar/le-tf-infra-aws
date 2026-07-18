#=============================#
# Cost Anomaly Detection      #
#=============================#
# Enables the FinOps Agent's headline anomaly-investigation feature. The agent reads
# anomalies produced by this monitor via ce:GetAnomalies / ce:GetAnomalyMonitors.
resource "aws_ce_anomaly_monitor" "service" {
  name              = var.anomaly_monitor_name
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = local.tags
}
