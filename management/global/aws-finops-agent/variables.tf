variable "agent_role_name" {
  description = "Name of the IAM role the FinOps Agent service assumes to read cost and operational data (wizard Step 2)."
  type        = string
  default     = "FinOpsAgentRole"
}

variable "operator_role_name" {
  description = "Name of the IAM role the FinOps Agent web app assumes for operator actions (wizard Step 3)."
  type        = string
  default     = "FinOpsAgentOperatorRole"
}

variable "anomaly_monitor_name" {
  description = "Name of the Cost Anomaly Detection monitor the agent investigates."
  type        = string
  default     = "finops-agent-service-monitor"
}

variable "enable_compute_optimizer" {
  description = "Opt the management account in to AWS Compute Optimizer (management account only; does not enroll member accounts)."
  type        = bool
  default     = true
}
