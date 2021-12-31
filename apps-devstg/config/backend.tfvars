#
# Backend Configuration
#

# AWS Profile (required by the backend but also used for other resources)
profile = "bb-apps-devstg-devops"

# S3 bucket
bucket = "bb-apps-devstg-terraform-backend"

# AWS Region (required by the backend but also used for other resources)
region = "us-east-1"

# Enable DynamoDB server-side encryption?
encrypt = true

# DynamoDB Table Name
dynamodb_table = "bb-apps-devstg-terraform-backend"
