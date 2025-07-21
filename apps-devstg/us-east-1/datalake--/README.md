# Datalake Layer

This Terraform layer is used for creating resources that are required by the datalake implemented in the Data Science account.

The resources defined here (such as Kinesis streams and Firehose delivery streams) are necessary for the datalake to function, but must be provisioned outside the datascience account itself. This layer is responsible for provisioning those supporting resources.

## Data Science Account Path

> `data-science/us-east-1/datalake-demo--/`
