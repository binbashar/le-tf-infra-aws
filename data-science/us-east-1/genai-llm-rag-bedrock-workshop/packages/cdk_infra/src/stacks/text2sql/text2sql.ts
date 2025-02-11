import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { NagSuppressions } from 'cdk-nag';
import { AthenaStack } from './athena-stack';
import { BedrockText2SqlAgentsStack } from './bedrock-text2sql-agent-stack';
import { BasicRestApiStack } from '../basic-rest-api-stack';
import { CommonStack } from '../common-stack';
import { BedrockKnowledgeBaseStack } from '../bedrock-kb-stack';

interface Text2SQLStackProps extends cdk.StackProps {
  env: cdk.Environment;
  stackNamePrefix: string;
  commonStack: CommonStack;
  bedrockKnowledgeBaseStack?: BedrockKnowledgeBaseStack;
}

export class Text2SQLStack extends cdk.Stack {

  constructor(
    scope: Construct,
    id: string,
    props: Text2SQLStackProps,
  ) {
    super(scope, id, props);

    // Create the AthenaStack
    const athenaStack = new AthenaStack(this, `AthenaStack`, {
      env: props.env,
      ACCESS_LOG_BUCKET: props.commonStack.ACCESS_LOG_BUCKET,
    });
    athenaStack.addDependency(props.commonStack);

    NagSuppressions.addStackSuppressions(athenaStack, [
      {
        id: "AwsSolutions-IAM4",
        reason: "Using AWS Managed Policies just for the scope of the prototype, these policies need to be created and maintain by the implementer of this solution",
      },
      {
        id: "AwsSolutions-IAM5",
        reason: "Using IAM Policies with wildcard iot action permissions, but with a restricted scope of only that account and region. This is done just for the scope of the prototype, these policies need to be created and maintain by the implementer of this solution",
      },
      {
        id: "AwsSolutions-L1",
        reason: "The non-container Lambda function is not configured to use the latest runtime version. This is due to the use of s3deploy.BucketDeployment, which is not updated to use latest runtime",
      },
    ]);

    // Create the BedrockText2SqlAgentsStack
    const bedrockText2SqlAgentsStack = new BedrockText2SqlAgentsStack(this, `AgentsStackText2Sql`, {
      env: props.env,
      LAYER_POWERTOOLS: props.commonStack.LAYER_POWERTOOLS,
      LAYER_BOTO: props.commonStack.LAYER_BOTO,
      LAYER_PYDANTIC: props.commonStack.LAYER_PYDANTIC,
      ATHENA_OUTPUT_BUCKET: athenaStack.ATHENA_OUTPUT_BUCKET,
      ATHENA_DATA_BUCKET: athenaStack.ATHENA_DATA_BUCKET,
      AGENT_KB: props.bedrockKnowledgeBaseStack?.AGENT_KB ?? null,
    });

    NagSuppressions.addStackSuppressions(bedrockText2SqlAgentsStack, [
      {
        id: "AwsSolutions-IAM4",
        reason: "Using AWS Managed Policies just for the scope of the prototype, these policies need to be created and maintain by the implementer of this solution",
      },
      {
        id: "AwsSolutions-IAM5",
        reason: "Using IAM Policies with wildcard iot action permissions, but with a restricted scope of only that account and region. This is done just for the scope of the prototype, these policies need to be created and maintain by the implementer of this solution",
      },
      {
        id: "AwsSolutions-L1",
        reason: "The non-container Lambda function is not configured to use the latest runtime version. This is due to the use of s3deploy.BucketDeployment, which is not updated to use latest runtime",
      },
    ]);

    // Create BasicRestApiStack for Text2SQL
    const text2SqlBasicRestApiStack = new BasicRestApiStack(this, `BasicRestApiStackText2sql`, {
      env: props.env,
      LAYER_POWERTOOLS: props.commonStack.LAYER_POWERTOOLS,
      LAYER_BOTO: props.commonStack.LAYER_BOTO,
      LAYER_PYDANTIC: props.commonStack.LAYER_PYDANTIC,
      AGENT: bedrockText2SqlAgentsStack.AGENT,
      AGENT_ALIAS: bedrockText2SqlAgentsStack.AGENT_ALIAS,
      AGENT_KB: props.bedrockKnowledgeBaseStack?.AGENT_KB ?? null,
      PREFIX: props.stackNamePrefix
    });
    text2SqlBasicRestApiStack.addDependency(bedrockText2SqlAgentsStack);

    NagSuppressions.addStackSuppressions(text2SqlBasicRestApiStack, [
      {
        id: "AwsSolutions-IAM4",
        reason: "Using AWS Managed Policies just for the scope of the prototype, these policies need to be created and maintain by the implementer of this solution",
      },
      {
        id: "AwsSolutions-IAM5",
        reason: "Using IAM Policies with wildcard iot action permissions, but with a restricted scope of only that account and region. This is done just for the scope of the prototype, these policies need to be created and maintain by the implementer of this solution",
      },
      {
        id: "AwsSolutions-L1",
        reason: "The non-container Lambda function is not configured to use the latest runtime version. This is due to the use of s3deploy.BucketDeployment, which is not updated to use latest runtime",
      },
      {
        id: "AwsSolutions-APIG2",
        reason: "The REST API does not have request validation enabled.",
      },
      {
        id: "AwsSolutions-APIG1",
        reason: "The API does not have access logging enabled.",
      },
      {
        id: "AwsSolutions-APIG6",
        reason: "The REST API Stage does not have CloudWatch logging enabled for all methods",
      },
      {
        id: "AwsSolutions-COG4",
        reason: "The API GW method does not use a Cognito user pool authorizer.",
      },
    ]);
  }
}