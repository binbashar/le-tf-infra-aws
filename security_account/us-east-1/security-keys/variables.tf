#===========================================#
# Security                                  #
#===========================================#
variable "compute_ssh_key_name" {
  type        = string
  description = "EC2 ssh public key name"
  default     = "bb-infra-deployer"
}

#
# For instance, you could run the following command to create ED keys:
#   ssh-keygen -t ed25519 -C "your.email@example.com"
#
variable "compute_ssh_public_key" {
  type        = string
  description = "EC2 ssh public key"
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVSbmJA5VwHXtZG9vBw3/oCbZIPNhFdRCTSYhGqlHZb binbash-security+default@binbash.com.ar"
}

variable "kms_key_name" {
  type        = string
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms"
}
