/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as path from "path";
import { Construct } from "constructs";
import * as cdk from "aws-cdk-lib";
import * as iam from "aws-cdk-lib/aws-iam";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as lambda from "aws-cdk-lib/aws-lambda";
import { PythonFunction } from "@aws-cdk/aws-lambda-python-alpha";
import { Runtime } from "aws-cdk-lib/aws-lambda";

/**
 * Properties for the Bedrock Data Automation Construct
 */
export interface BedrockDataAutomationConstructProps {
  /**
   * Input bucket for document files
   */
  bdaInputBucket: s3.Bucket;
  
  /**
   * Output bucket for processed results
   */
  bdaOutputBucket: s3.Bucket;
  
  /**
   * Whether to create a Bedrock Data Automation project
   * @default false
   */
  isProjectRequired?: boolean;
  
  /**
   * Whether to create blueprint functionality
   * @default false
   */
  isBlueprintRequired?: boolean;
  
  /**
   * Whether to create status check functionality
   * @default false
   */
  isStatusRequired?: boolean;
  
  /**
   * Name of the Bedrock Data Automation project
   */
  projectName?: string;
}

/**
 * Bedrock Data Automation Construct
 * 
 * This construct implements AWS Bedrock Data Automation for document processing.
 * It's a wrapper around the blueprint creation, document processing, and results
 * functionality needed for KYB document processing.
 */
export class BedrockDataAutomationConstruct extends Construct {
  /**
   * The blueprint creation/management Lambda function
   */
  public readonly bdaBlueprintFunction: lambda.Function;
  
  /**
   * The data processing invocation Lambda function
   */
  public readonly bdaInvocationFunction: lambda.Function;
  
  /**
   * The results retrieval Lambda function
   */
  public readonly bdaResultsFunction: lambda.Function;
  
  /**
   * The status check Lambda function
   */
  public readonly bdaResultStatusFunction: lambda.Function;
  
  /**
   * The project ID
   */
  public readonly projectId: string;

  constructor(scope: Construct, id: string, props: BedrockDataAutomationConstructProps) {
    super(scope, id);

    // Set default values
    const isProjectRequired = props.isProjectRequired ?? false;
    const isBlueprintRequired = props.isBlueprintRequired ?? false;
    const isStatusRequired = props.isStatusRequired ?? false;
    const projectName = props.projectName ?? `bda-project-${cdk.Names.uniqueId(this)}`.toLowerCase();
    
    this.projectId = projectName;

    // Create role with Bedrock permissions
    const bedrockRole = new iam.Role(this, 'BedrockAccessRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonBedrockFullAccess')
      ]
    });

    // Add S3 permissions
    props.bdaInputBucket.grantRead(bedrockRole);
    props.bdaOutputBucket.grantReadWrite(bedrockRole);

    // Create the blueprint Lambda function if required
    if (isBlueprintRequired) {
      this.bdaBlueprintFunction = new PythonFunction(this, 'BlueprintFunction', {
        functionName: `bda-bp-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        entry: path.join(__dirname, "../src/backend/documentprocessing/lambda/blueprint_creation"),
        index: "blueprint_creation.py",
        handler: "lambda_handler",
        runtime: Runtime.PYTHON_3_11,
        timeout: cdk.Duration.minutes(5),
        memorySize: 512,
        role: bedrockRole,
        environment: {
          "BDA_PROJECT_ID": projectName
        }
      });
    } else {
      // Create a placeholder Lambda if not required
      this.bdaBlueprintFunction = new lambda.Function(this, 'BlueprintFunction', {
        functionName: `bda-bp-placeholder-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        code: lambda.Code.fromInline(`
          def handler(event, context):
              return {"statusCode": 501, "body": "Blueprint functionality not enabled"}
        `),
        handler: 'index.handler',
        runtime: Runtime.PYTHON_3_9,
      });
    }

    // Create the invocation Lambda function
    this.bdaInvocationFunction = new PythonFunction(this, 'InvocationFunction', {
      functionName: `bda-invoke-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      entry: path.join(__dirname, "../src/backend/documentprocessing/lambda/processing"),
      index: "processing.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: cdk.Duration.minutes(15),
      memorySize: 1024,
      role: bedrockRole,
      environment: {
        "INPUT_BUCKET": props.bdaInputBucket.bucketName,
        "OUTPUT_BUCKET": props.bdaOutputBucket.bucketName,
        "BDA_PROJECT_ID": projectName
      }
    });

    // Create the results Lambda function
    this.bdaResultsFunction = new lambda.Function(this, 'ResultsFunction', {
      functionName: `bda-results-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      code: lambda.Code.fromAsset(path.join(__dirname, "../src/backend/documentprocessing/lambda/processing")),
      handler: 'processing.lambda_handler',
      runtime: Runtime.PYTHON_3_11,
      timeout: cdk.Duration.minutes(5),
      memorySize: 512,
      role: bedrockRole,
      environment: {
        "OUTPUT_BUCKET": props.bdaOutputBucket.bucketName,
        "BDA_PROJECT_ID": projectName
      }
    });

    // Create the status check Lambda function if required
    if (isStatusRequired) {
      this.bdaResultStatusFunction = new lambda.Function(this, 'StatusFunction', {
        functionName: `bda-status-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        code: lambda.Code.fromAsset(path.join(__dirname, "../src/backend/documentprocessing/lambda/processing")),
        handler: 'processing.lambda_handler',
        runtime: Runtime.PYTHON_3_11,
        timeout: cdk.Duration.minutes(5),
        memorySize: 512,
        role: bedrockRole,
        environment: {
          "OUTPUT_BUCKET": props.bdaOutputBucket.bucketName,
          "BDA_PROJECT_ID": projectName
        }
      });
    } else {
      // Create a placeholder Lambda if not required
      this.bdaResultStatusFunction = new lambda.Function(this, 'StatusFunction', {
        functionName: `bda-status-placeholder-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        code: lambda.Code.fromInline(`
          def handler(event, context):
              return {"statusCode": 501, "body": "Status functionality not enabled"}
        `),
        handler: 'index.handler',
        runtime: Runtime.PYTHON_3_9,
      });
    }
  }
} 