project = "devstg"
environment = "devstg"
profile = "bb-shared-devops"

regions = [
  "us-east-1",
  "us-east-2"
]

kms_settings = {
  key_name = "kms"
  enabled = true
  description = "KMS key for the account"
  delimiter = "-"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

#ssh_settings = {
#  key_name = "ssh"
#  public_key = "xfvg-ssh-key"
#}

accounts = {
  security = {
    id = "900980591242"
  }
}
