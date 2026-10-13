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
