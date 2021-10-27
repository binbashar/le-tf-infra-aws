# Project (short name)
project         = "bb"

# Project (long name)
project_long    = "binbash"

# AWS Region for DR replication (required by the backend but also used for other resources)
region_secondary      = "us-east-2"

# Account IDs
root_account_id       = "754065527950"
security_account_id   = "900980591242"
shared_account_id     = "763606934258"
network_account_id    = "822280187662"
appsdevstg_account_id = "523857393444"
appsprd_account_id    = "802787198489"

# Hashicorp Vault private API endpoint
vault_address = "https://bb-le-shared-vault-cluster.private.vault.11eb5727-ed8f-98cd-a33c-0242ac110007.aws.hashicorp.cloud:8200"

# Hashicorp Vault token
#
# Vault token that will be used by Terraform to authenticate.
# 1st exec: admin token from https://portal.cloud.hashicorp.com/.
# Following execs:
#   1- Generate GitHub personal access token: https://github.com/settings/tokens
#   2- Click “Generate new token“
#   3- Choose one permission that is required: read:org
#
#  Get vault token from your GH one
#   1- docker run -it vault:1.7.2 sh
#   2- export VAULT_ADDR="https://vault-cluster.private.vault.XXXXXX.aws.hashicorp.cloud:8200"; export VAULT_NAMESPACE="admin"
#   3- vault login -method=github
#   5- input your GH personal access token
#   6- Set /config/common.tfvars -> vault_token="XXXXXXXXXXXXXXXXXXXXXXX"
#
#   NOTE: the admin token from https://portal.cloud.hashicorp.com/ will always work
#   but it's use is defavoured for the nominated GH personal access token for
#   security audit trail reasons
#
vault_token = "s.SYwPmjAFHXp47TJ4jiVwz17x.hbtct"
