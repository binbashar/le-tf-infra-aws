#===========================================#
# Security                                  #
#===========================================#
variable "compute_ssh_key_name" {
  type        = string
  description = "EC2 ssh public key name"
  default     = "apps-devstg-default"
}

variable "compute_ssh_public_key" {
  type        = string
  description = "EC2 ssh public key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3OoNqa58Pu+rhpWX3rGhyziG3XQ2ApsBl2CTqJdK6AEQlrR0FHp95tyeplkkNtqD3ToShMrI1w00CodhLycNFwv8/vlJKrkTWlmv0QXB/erLNBsRjp0BTUraCGqq/sB2qb2zeG/K4zalxVg/KiTzgHZRKSvx5s4ft8I6CHro65UZtA25MC1hKrjOgiRWYG7iz9/Frxrh7yAZiaZjac70EofuT0GXq7S3znuhJ1V8LS2j8sb7JfnbL5Td8RZcgh72rkpNHscs09FUZqOllQV8ZeBBeEBhPOxZ06xVB780GeP1nQf4y7ZdLsIOUZt5g333G2VXtHx1bCo+tSgSxXlVjxwiZf/6kCerBrzanu5Qnd6GUkn0RsvsBITWsqf+wmejJYqS+sgdn0mQg4pvKu4ORigDetr9oE8Veba5LhpyZYjn5um+vQQxgY/P4Dj6uD0rozoH5VBt9QaSggeiJRE7OQKaXD2zJj1toQotSXy/WGhaMJRtY+jynBKvkvGx8y9gXhQd/2OJBu3+fgrse+TrWlMmo+baF4HxF0H+5ug3qmoiSxRgn1GQW2AKev6NcxeO5xGYiJmgUMwSG/BiDB/0cFKk/9F2tNMHBpZIHgTpAmYuOk/h6R3Kqm4nvlb/dULiwKa2a1LWFtRnrdIsgO00jGEOvf8iHxMQfJaLzc4auxQ== binbash-aws-dev@binbash.com.ar"
}

variable "kms_key_name" {
  type        = string
  description = "KMS key solution name, e.g. 'app' or 'jenkins'"
  default     = "kms"
}
