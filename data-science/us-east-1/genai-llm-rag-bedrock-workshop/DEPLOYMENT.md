# Deployment Guide

This guide provides step-by-step instructions for deploying the Binbash Generative AI Developer Workshop project.

## Overview

Follow this guide after reviewing the [prerequisites in the main README](README.md#prerequisites).

This document provides comprehensive setup instructions for:
- Backend infrastructure
- Frontend application
- All use cases: Chatbot, Text2SQL, and Document Processing

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Install Project Dependencies](#install-project-dependencies)
3. [CDK Infrastructure Deployment](#cdk-infrastructure-deployment)
4. [Knowledge Base Synchronization (Optional)](#knowledge-base-synchronization-optional)
5. [Web UI Deployment](#web-ui-deployment)
6. [Customization](#customization)
7. [Testing](#testing)
8. [Cleanup](#cleanup)

## Before You Start

- First, verify you are logged into your AWS Account, and using the right region.

```bash
aws sts get-caller-identity
aws configure get region
```

- If you are logged into another account, and you want to use an account that is in another profile  for this workshop, execute the following.
```bash
export AWS_PROFILE=your_profile_for_this_workshop
```

Recommended region: `us-west-2`
- If you use a different region, ensure [the AWS services](packages/cdk_infra/README.md) and [foundation models required for this project](./README.md/#required-aws-setup) are supported in your chosen region.
- Using a different region will require changing region settings in some subsequent steps. Guidance for these changes will be provided later in the instructions.

To set or change your default AWS CLI region, use: 
```bash
aws configure set default.region <REGION NAME>
```
Replace <REGION NAME> with your desired region (e.g., `us-west-2`).

- Check if CDK is bootstrapped in your account:
   1. Go to the [Amazon CloudFormation console](https://console.aws.amazon.com/cloudformation).
   2. Look for a stack named `CDKToolkit`.
   3. If the `CDKToolkit` stack exists, CDK has already been bootstrapped in your account and region.
   4. If you don't see the `CDKToolkit` stack, you need to bootstrap CDK. Run the following command:
     ```bash
     cdk bootstrap aws://ACCOUNT-NUMBER/REGION
     ```

   > Note: CDK bootstrapping is a one-time setup process for each account/region combination where you want to deploy CDK stacks.

- Ensure Docker engine is running.

## Install Project Dependencies

1. From the repository root directory, install all dependencies:

    ```bash
    pnpm install
    ```

   > Note: This command will install dependencies for both frontend and backend components.

## CDK Infrastructure Deployment

> Ensure you run all the `pnpm` commands in the **root** directory of the project

1. Configure the [cdk.json](packages/cdk_infra/cdk.json) file under `/packages/cdk_infra`:
    - Set `"custom:companyName"` to your company name
    - Set `"custom:agentName"` to your agent's name
    - Choose your use case:
        - `"deploy:case"`: Select `chatbot`, `text2sql`, `documentprocessing` or `all` (case-insensitive)
        - `"deploy:knowledgebase"`:
            - For `chatbot`: Set to `true` if you want to deploy a knowledge base
            - For `text2sql`: Typically set to `false` (set to `true` only if you need a specific knowledge base)
            - For `documentprocessing`: Set to `false` (knowledge base not required)
            - For `all`: Set to `true` if you want to deploy a knowledge base. This will deploy the knowledge base for the chatbot use case

   Example for Text2SQL use case:
   ```json
   "context": {
     "custom:companyName": "Acme Corp",
     "custom:agentName": "Galileo",
     "deploy:case": "text2sql",
     "deploy:knowledgebase": false
   }
   ```

   > Note: The deployment will fail if the `deploy:case` is not set to one of `chatbot`, `text2sql`, `documentprocessing` or `all`.

   2. CDK Infrastructure Project Build

       ```bash
       pnpm cdk synth
       ```

      If you're not using the `us-west-2` region, you need to update the Foundation Model (FM) ID:

      1. Ensure you're using the correct model ID for your region. By default, the workshop uses the `us-west-2` region.

      2. Locate the file where the model ID is defined: 
         - For the Chatbot: `packages/cdk_infra/src/stacks/bedrock-agent-stacks.ts`
         - For Text2SQL: `packages/cdk_infra/src/stacks/bedrock-text2sql-agent-stacks.ts`
         - For Document Processing: `packages/cdk_infra/src/stacks/bedrock-bda-agent-stack.ts`

      3. Check the model ARN in your code. For example, the default Claude 3 Sonnet model ARN for `us-west-2` is:
           ```typescript
           "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"
           ``` 
      4. If you're deploying to a different region, update the ARN accordingly in the appropriate file based on your deployment case.

      5. If you're using another model, update the property that is linked to a model by searching for:
         ```typescript
           "bedrock.BedrockFoundationModel"
           ``` 
      > Note: We recommend to use bedrock.BedrockFoundationModel.ANTHROPIC_CLAUDE_3_5_SONNET_V2_0 . Make sure the chosen model is available in your selected region. 

3. Deploy the infrastructure stack (`cdk_infra`)

   ```bash
   pnpm cdk_infra:deploy
   ```

4. After deployment, view the auto-generated architecture diagram:
    - Navigate to `packages/cdk_infra/cdk.out/cdkgraph/`
    - Open `diagram.png` to see detailed resource information


## Knowledge Base Synchronization

> Note: This step is **only required** if you set `"deploy:knowledgebase": true` in your configuration.

### Synchronization Process

1. Open [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock)
2. Navigate to **Knowledge bases**
3. Select `KBBedrockAgenowledgeBase`
4. Click on the **Amazon S3 Data source**
5. Choose **Sync** to convert raw data into vector embeddings

> Important: Without synchronization, the Bedrock Agent cannot interact with the knowledge base. This step is crucial for enabling agent functionality.

### Sample Data

Sample PDF files are located at `/packages/cdk_infra/src/assets/knowledgebase`

The CDK deployment uploads:
- Sample PDF files about Lambda and Bedrock quotas
- Accompanying metadata files to demonstrate [metadata filtering](#metadata-filtering-for-knowledge-base)

> Note: These PDFs are for demonstration only and may be outdated. Always refer to the latest AWS official documentation for current information.

## Web UI Deployment

After deploying the packages/cdk_infra project, you'll have a sample Amazon Cognito User Pool with predefined users:

| Username | Group          |
|----------|----------------|
| Admin    | ADMIN          |
| writer   | READ_AND_WRITE |
| reader   | READONLY       |

### Set Default Passwords for Sample Cognito Users

1. Navigate to the Amazon Cognito Console and locate your User Pool ID

2. Set passwords for sample users using AWS CLI:
   ```bash
   aws cognito-idp admin-set-user-password \
     --user-pool-id <User Pool Id> \
     --username <USERNAME> \
     --password <PASSWORD>
   ```

### Configure AWS Exports

1. Collect the following from the Amazon Cognito Console:

    - User Pool ID
    - Identity Pool ID
    - Web Client ID
        - Find your User Pool
        - Click UserPoolWebClient and copy the Client ID

2. Update [aws-exports.js](packages/reactjs_ui/src/aws-exports.js) file with the collected values (located at `packages/reactjs_ui/src`). Replace the example values in the file with your own:

   ```json
   {
    "aws_project_region": "us-west-2",
    "aws_cognito_identity_pool_id": "us-west-2:f7be1f09-0202-4700-8fa8-55346a2ec4f5",
    "aws_cognito_region": "us-west-2",
    "aws_user_pools_id": "us-west-2_e2bc0Jiyk",
    "aws_user_pools_web_client_id": "60pgcj9fas0cig379pkicri954"
   }
   ```
   - If you're not using the `us-west-2` region, update both `aws_project_region` and `aws_cognito_region` in this file to match your deployment region

### Build and Run the Web Application

1. Build the ReactJS UI:
   ```bash
   pnpm vite
   ```

2. Open your browser and visit http://localhost:5173

3. Login with available users: `admin`, `reader`, or `writer`

   > Important: Reset passwords for these users in the [Set Default Passwords for Sample Cognito Users](#set-default-passwords-for-sample-cognito-users) step.

   First-time Login Requirements:
    - Update initial password
        - You can reuse the password set in the previous step
    - Provide:
        - Email (can be a fake address)
        - Family name
        - Given name

   > Tip: For this demo, you can skip email verification.

4. For detailed UI instructions, refer to the [Frontend Implementation](packages/reactjs_ui/README.md#getting-started)


## Customization

For detailed instructions on customizing your deployment:
- [Chatbot Customization Guide](docs/CUSTOMIZATION.md#chatbot-customization)
- [Text2SQL Customization Guide](docs/CUSTOMIZATION.md#text2sql-customization)
- [Document Processing Customization Guide](docs/CUSTOMIZATION.md#document-processing-customization)

## Testing

For API testing instructions, refer to the [API Testing Guide](docs/API_TESTING.md).

## Cleanup

When you're finished with the workshop, follow the [Cleanup Guide](docs/CLEANUP.md) to remove all deployed resources.

For any issues or questions during deployment, please check our [FAQ](docs/FAQ.md) or open an issue in the repository.

