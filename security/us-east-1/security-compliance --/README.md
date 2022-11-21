# AWS Config Centralized bucket
This layer creates a bucket for AWS Config which centralizes all snapshots and logs from other AWS Config instances in each accounts and region. It also creates an aggregator for all accounts in the organization, therefore all resources, rules can be visualized in the AWS Config Dashboard of the security account.

All Config snapshots are stored following a directories structure similar to AWS CloudTrail's:

```
AWSLOGS
    ACCOUNT_ID-1
        Config
            REGION-1
            REGION-2
            ...
    ACCOUNT_ID-2
        Config
            REGION-1
            REGION-2
            ...
    ...
```

# AWS Config bucket replication

AWS Config snapshots are saved in a S3 Bucket of the primary region as defined in the `/security/us-east-1/security-compliance/awsconfig.tf`.

In order to replicate the AWS Config bucket to a secondary region, apply the [/security/us-east-2/security-compliance](/security/us-east-2/security-compliance) layer. The `awsconfig-replication.tf` file has a data source aiming to the AWS Config bucket in the primary region.


# AWS inspector

Steps to enable inspector:  
* Switch boolean to true in the global config file ([/config/common.tfvars](/config)) that you create for your project.
* Delegate administration to security account by running `leverage terraform apply` in management security-compliance layer ([/management/us-east-1/security-compliance](/management/us-east-1/security-compliance)). You'd need to do this in every region you want to enable inspector.
* Enable inspector in the security account by running `leverage terraform apply` in the security-compliance layer for that account, also per region ([/security/us-east-1/security-compliance](/security/us-east-1/security-compliance%20--)):
  * Add inspector account members as needed in `locals.tf` file (create if doesn't exist), which inspector is going to enabled and start monitoring.