import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { NagSuppressions } from 'cdk-nag';
import { BedrockDocumentProcessingStack } from './bedrock-bda-agent-stack';
import { BasicRestApiStack } from '../basic-rest-api-stack';
import { CommonStack } from '../common-stack';
import { BedrockKnowledgeBaseStack } from '../bedrock-kb-stack';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { RemovalPolicy } from 'aws-cdk-lib';

interface DocumentProcessingStackProps extends cdk.StackProps {
  env: cdk.Environment;
  stackNamePrefix: string;
  commonStack: CommonStack;
  bedrockKnowledgeBaseStack?: BedrockKnowledgeBaseStack;
}

export class DocumentProcessingStack extends cdk.Stack {
  public readonly DOCUMENT_INPUT_BUCKET: s3.Bucket;
  public readonly DOCUMENT_OUTPUT_BUCKET: s3.Bucket;

  constructor(
    scope: Construct,
    id: string,
    props: DocumentProcessingStackProps,
  ) {
    super(scope, id, props);

    // Create document processing buckets
    this.DOCUMENT_INPUT_BUCKET = new s3.Bucket(this, "DocumentInputBucket", {
      enforceSSL: true,
      versioned: true,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    this.DOCUMENT_OUTPUT_BUCKET = new s3.Bucket(this, "DocumentOutputBucket", {
      enforceSSL: true,
      versioned: true,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Create the BedrockDocumentProcessingStack
    const bedrockDocumentProcessingStack = new BedrockDocumentProcessingStack(this, `DocumentProcessingStack`, {
      env: props.env,
      LAYER_POWERTOOLS: props.commonStack.LAYER_POWERTOOLS,
      LAYER_BOTO: props.commonStack.LAYER_BOTO,
      LAYER_PYDANTIC: props.commonStack.LAYER_PYDANTIC,
      INPUT_BUCKET: this.DOCUMENT_INPUT_BUCKET,
      OUTPUT_BUCKET: this.DOCUMENT_OUTPUT_BUCKET,
    });

    NagSuppressions.addStackSuppressions(bedrockDocumentProcessingStack, [
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

    // Create BasicRestApiStack for Document Processing
    const documentProcessingBasicRestApiStack = new BasicRestApiStack(this, `BasicRestApiStackDocumentProcessing`, {
      env: props.env,
      LAYER_POWERTOOLS: props.commonStack.LAYER_POWERTOOLS,
      LAYER_BOTO: props.commonStack.LAYER_BOTO,
      LAYER_PYDANTIC: props.commonStack.LAYER_PYDANTIC,
      DOCUMENT_INPUT_BUCKET: this.DOCUMENT_INPUT_BUCKET,
      DOCUMENT_OUTPUT_BUCKET: this.DOCUMENT_OUTPUT_BUCKET,
      AGENT: bedrockDocumentProcessingStack.AGENT,
      AGENT_ALIAS: bedrockDocumentProcessingStack.AGENT_ALIAS,
      PREFIX: props.stackNamePrefix
    });
    documentProcessingBasicRestApiStack.addDependency(bedrockDocumentProcessingStack);

    NagSuppressions.addStackSuppressions(documentProcessingBasicRestApiStack, [
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