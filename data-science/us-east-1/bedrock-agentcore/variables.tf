variable "artifact_path" {
  description = "Path to the agent deployment zip (relative to layer). Build it before running leverage tf apply."
  type        = string
  default     = ".build/agent.zip"
}

variable "runtime_name" {
  description = "AgentCore runtime Python version"
  type        = string
  default     = "PYTHON_3_12"
}

variable "entry_point" {
  description = "Entrypoint file(s) for the agent runtime"
  type        = list(string)
  default     = ["agent.py"]
}

variable "runtime_description" {
  description = "Description for the agent runtime"
  type        = string
  default     = "Bedrock AgentCore runtime deployed via Leverage"
}

variable "endpoint_description" {
  description = "Description for the runtime endpoint"
  type        = string
  default     = "Bedrock AgentCore endpoint deployed via Leverage"
}

variable "environment_variables" {
  description = "Environment variables passed to the agent runtime"
  type        = map(string)
  default     = {}
}
