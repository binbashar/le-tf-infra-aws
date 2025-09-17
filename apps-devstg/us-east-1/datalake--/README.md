# Datalake Layer

This Terraform layer is used for creating resources that are required by the datalake implemented in the Data Science account.

The resources defined here (such as Kinesis streams and Firehose delivery streams) are necessary for the datalake to function, but must be provisioned outside the datascience account itself. This layer is responsible for provisioning those supporting resources.

## Architecture Overview

This layer creates a **real-time data pipeline** that moves data from DynamoDB (in the apps-devstg account) to the data lake (in the data-science account) using:

1. **Kinesis Data Stream**: Captures DynamoDB changes via CDC (Change Data Capture)
2. **Kinesis Firehose**: Delivers the streamed data to the S3 raw bucket in the data-science account
3. **DynamoDB Kinesis Streaming**: Enables DynamoDB to stream changes to Kinesis

## Prerequisites

Before applying this layer, ensure the following dependencies are met:

### 1. DynamoDB Layer (Required First)
The DynamoDB layer must be applied first as this layer depends on the DynamoDB table:
```bash
cd ../databases-dynamodb--
leverage tf apply
```

### 2. Data Science Account - Datalake Layer
The S3 raw bucket must be created in the data-science account:
```bash
# In data-science account
cd data-science/us-east-1/datalake-demo--
leverage tf apply
```

### 3. Data Science Account - Lakehouse Layer (Optional but Recommended)
For complete data processing capabilities, also apply the lakehouse layer:
```bash
# In data-science account  
cd data-science/us-east-1/lakehouse-demo--
leverage tf apply
```

## Data Flow

```
DynamoDB (apps-devstg)
    ↓ [CDC via Kinesis Streaming]
Kinesis Data Stream (apps-devstg)
    ↓ [Firehose Delivery]
S3 Raw Bucket (data-science/datalake-demo)
    ↓ [Glue ETL Processing]
S3 Processed Bucket (data-science/lakehouse-demo)
```

## Data Science Account Paths

- **Datalake Layer**: `data-science/us-east-1/datalake-demo--/`
- **Lakehouse Layer**: `data-science/us-east-1/lakehouse-demo--/`
