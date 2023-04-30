# Wazuh on EC2 via AWS Marketplace

## Manual Steps
- Deploy the resources via this layer (mainly permissions to CloudTrail bucket)
- Deploy the EC2 instance via MarketPlace Subscriptions (it should be free unless you need a support plan)
- Configure Wazuh
    - Change default admin password
    - Enable Amazon AWS module via Wazuh UI
    - Enable CloudTrail support via SSH (refer to the official docs)
        - No internet required if you use S3 VPC Endpoints
    - Enable alert notification via Slack via SSH (refer to the official docs)
        - Internet access required

## TODO
- Can we deploy the EC2 instance via Terraform as well?
- The security group used by the instance should also be defined via Terraform
