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

In order to replicate the AWS Config bucket to a secondary region, apply the the /security/us-east-2(/security-compliance layer. The `awsconfig-replication.tf` file has a data source aiming to the AWS Config bucket in the primary region.