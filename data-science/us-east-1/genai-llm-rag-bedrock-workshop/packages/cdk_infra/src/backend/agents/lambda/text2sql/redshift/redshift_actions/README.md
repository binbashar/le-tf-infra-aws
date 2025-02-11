# Reshift Actions

This repository contains the code for the Amazon Bedrock Agent's action group Lambda function. The Lambda function is part of a solution to enable custom integrations between Amazon Redshift and Amazon Bedrock services.

### File Structure

- `redshift_actions.py`: Contains the main logic for interacting with Redshift and processing the actions for the Lambda function.
- `__init__.py`: Initialization script for the Lambda function. It may include initialization of resources, libraries, or configuration settings necessary for the function's operation.
- `openapi.json`: Contains the JSON schema used to define the Bedrock actions. This schema is essential for defining how Bedrock will interact with the Lambda function for specific actions.

### Prerequisites

1. **Environment Variables for Lambda**
   - You need to set up appropriate environment variables for the Lambda function to operate correctly. These environment variables include configuration details such as credentials, and resource identifiers.

    ```python
    secret_name = environ.get('SECRET_NAME')
    database = environ.get('DATABASE')
    cluster_id = environ.get('CLUSTER_ID')
    ```

2. **Security Group and VPC Settings**
   - The Lambda function needs to be executed within a specific Virtual Private Cloud (VPC) and security group to ensure secure access to the required resources, like Amazon Redshift clusters. You will need to configure VPC and security group settings before deploying the Lambda function.
   - Make sure the Lambda function has the correct IAM roles and permissions to interact with resources like Redshift, AWS Bedrock, and any other AWS services involved.
   - Ensure if the Lambda function has a network access to the Redshift cluster. If you are using isolated private subnets, create VPC endpoints so that the Lambda function can access:
     - Redshift Data
     - Redshift
     - Secrets Manager

### Configuration Steps

1. **Deploy Lambda Function**
   - Deploy the Lambda function to your AWS environment by following these steps:
     - Upload `redshift_actions.py` and `__init__.py` to AWS Lambda.
     - Set the necessary environment variables, such as AWS region, Redshift connection details, and other configuration options.
     - Ensure that your Lambda function is configured to run within the correct VPC and security group, providing it with access to Amazon Redshift and Bedrock services.

2. **Set VPC and Security Group Settings**
   - Ensure the Lambda function is running in a VPC with access to your Redshift cluster and the necessary endpoints for Bedrock.
   - The Lambda function will require appropriate IAM permissions to access Redshift, interact with Bedrock, and send/receive data as needed.

3. **Adding Bedrock Actions with `openapi.json`**
   - The `openapi.json` file contains the schema used to define actions that Amazon Bedrock will take when interacting with the Lambda function. You can use the OpenAPI specification to define and customize actions that Bedrock can trigger in response to specific events.

### Lambda Permissions

Ensure the Lambda function has the necessary permissions by attaching the following IAM policies to its execution role: Here's a CDK example for your reference.

```ts
    // IAM Role for Query Action Lambda with VPC Access
    const redshiftQueryRole = new Role(this, "redshiftQueryRole", {
      assumedBy: new ServicePrincipal("lambda.amazonaws.com"),
      roleName: "redshiftQueryRole",
      managedPolicies: [
        ManagedPolicy.fromAwsManagedPolicyName("service-role/AWSLambdaVPCAccessExecutionRole")
      ],
    });
    // Add an inline policy to give a permission to Secrets Manager
    redshiftQueryRole.attachInlinePolicy(new Policy(this, "SecretsManagerAccess", {
      statements: [new PolicyStatement({
        effect: Effect.ALLOW,
        actions: ["secretsmanager:*"],
        resources: [ this.node.tryGetContext("custom:secretArn") ],
      })],
    }));
    // Add an inline policy to give access to the Redshift Database
    redshiftQueryRole.attachInlinePolicy(new Policy(this, "RedshiftStatementsAccess", {
      statements: [new PolicyStatement({
        effect: Effect.ALLOW,
        actions: [
          "redshift-data:GetStatementResult",
          "redshift-data:CancelStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:ListStatements"
        ],
        resources: [ "*" ]
      })],
    }));
    // Add an inline policy to give access to the Redshift Cluster
    redshiftQueryRole.attachInlinePolicy(new Policy(this, "RedshiftDataAPIAccess", {
      statements: [new PolicyStatement({
        effect: Effect.ALLOW,
        actions: ["redshift-data:*"],
        resources: [ 
          "arn:aws:redshift:*:*:cluster:" + this.node.tryGetContext("custom:clusterId")
        ]
      })],
    }));
```