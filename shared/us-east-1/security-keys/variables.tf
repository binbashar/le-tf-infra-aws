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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwqY8pH6XktrIOZ4JK2eaWg4QRkIkr2ua4IqfPhU+RPzCdBLCv1imX9kevX+dd0rplQAHibagouwLie99rEv1qR1Lt82jOXkBACdLCDaW5CGn2LTKFHN3Lm+oFRu9jzKRB6d2hm0qNuECvL1X2QAgbeGq5RDTwxVLg33l/EggpNbZZoh11w/UrSkvy2wYuYtLAN5oGj47+mvxpRvrcYK99zMOla6M6C5MrxllxaNcZXaO7cHZFLNFG5mbfJ/MdzHy9u46v3cf012UzhkrSkCqLSz2r2U25gKNWcOqmE0AMNW6qLBWmXnG+wUEBebX9v4KDRKfjbxpWJLQdr5CHav4l delivery@delivery-I7567"
}

variable "kms_key_name" {
  type        = string
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms"
}
