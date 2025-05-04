/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { readFileSync } from "fs";
import * as path from "path";
import {
  PythonFunction,
  PythonLayerVersion,
} from "@aws-cdk/aws-lambda-python-alpha";
import {
  bedrock,
  BedrockCwDashboard,
} from "@cdklabs/generative-ai-cdk-constructs";
import {
  AgentActionGroup,
  PromptCreationMode,
  PromptState,
} from "@cdklabs/generative-ai-cdk-constructs/lib/cdk-lib/bedrock";
import { Stack, StackProps, Duration } from "aws-cdk-lib";
import * as iam from "aws-cdk-lib/aws-iam";
import { Runtime, LayerVersion } from "aws-cdk-lib/aws-lambda";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as stepfunctions from "aws-cdk-lib/aws-stepfunctions";
import * as tasks from "aws-cdk-lib/aws-stepfunctions-tasks";
import * as events from "aws-cdk-lib/aws-events";
import * as targets from "aws-cdk-lib/aws-events-targets";
import * as cdk from "aws-cdk-lib/core";
// Import AwsCustomResource and Provider
import * as custom from "aws-cdk-lib/custom-resources";
import * as logs from "aws-cdk-lib/aws-logs"; // Import logs for Provider
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

/**
 * Properties for the Bedrock Data Automation Construct
 */
interface BedrockDataAutomationConstructProps {
  /**
   * Input bucket for document files
   */
  bdaInputBucketName: string;
  
  /**
   * Output bucket for processed results
   */
  bdaOutputBucketName: string;
  
  /**
   * Whether to create a Bedrock Data Automation project
   * @default false // NOTE: We will now likely always create it if the construct is used
   */
  isProjectRequired?: boolean; // This might become redundant
  
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
  projectNameInput?: string; // Renamed from projectName
  
  /**
   * Description for the Bedrock Data Automation project
   */
  projectDescription?: string; // Added
  
  /**
   * Boto3 Lambda Layer Version
   */
  layerBoto: PythonLayerVersion;
  
  /**
   * Whether to enable KYB workflow
   * @default false
   */
  isKYBEnabled?: boolean;
}

/**
 * Bedrock Data Automation Construct
 * 
 * This construct implements AWS Bedrock Data Automation for document processing.
 * It creates the BDA project via a Lambda function invoked during deployment,
 * and optionally the Lambda functions for blueprint management, document processing, and results retrieval.
 */
class BedrockDataAutomation extends Construct {
  /**
   * The blueprint creation/management Lambda function (if created)
   */
  public readonly bdaBlueprintFunction?: lambda.Function;
  
  /**
   * The data processing invocation Lambda function
   */
  public readonly bdaInvocationFunction: lambda.Function;
  
  /**
   * The results retrieval Lambda function
   */
  public readonly bdaResultsFunction: lambda.Function;
  
  /**
   * The status check Lambda function (if created)
   */
  public readonly bdaResultStatusFunction?: lambda.Function;
  
  /**
   * The actual ID of the BDA project (retrieved or created by Lambda)
   */
  public readonly projectId: string;

  constructor(scope: Construct, id: string, props: BedrockDataAutomationConstructProps) {
    super(scope, id);

    // Set default values
    const isBlueprintRequired = props.isBlueprintRequired ?? false;
    const isStatusRequired = props.isStatusRequired ?? false;
    const projectName = props.projectNameInput ?? `bda-project-${cdk.Names.uniqueId(this)}`.toLowerCase();
    const projectDescription = props.projectDescription ?? "CDK-managed BDA project for document processing";

    // --- Define BDA Project Handler Lambda ---
    const bdaProjectHandlerRole = new iam.Role(this, 'BdaProjectHandlerRole', {
        assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
        managedPolicies: [iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole')]
    });
    bdaProjectHandlerRole.addToPolicy(new iam.PolicyStatement({
        actions: [
            "bedrock-data-automation:ListProjects",
            "bedrock-data-automation:CreateDataAutomationProject",
            "bedrock-data-automation:DeleteDataAutomationProject"
            // Add Get* if needed for updates/verification
        ],
        resources: ["*"], // Needs broad permissions to list/create, delete uses ID passed in
        effect: iam.Effect.ALLOW,
    }));

    const bdaProjectHandlerFunction = new PythonFunction(this, 'BdaProjectHandlerFunction', {
        functionName: `bda-projhandler-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        entry: path.join(__dirname, "../../../src/backend/documentprocessing/lambda/bda_project_handler"),
        index: "project_handler.py",
        handler: "lambda_handler",
        runtime: Runtime.PYTHON_3_11, // Match the python code
        timeout: Duration.minutes(2), // CFN custom resources have a timeout
        memorySize: 256,
        role: bdaProjectHandlerRole,
        layers: [props.layerBoto], // Ensure boto layer is added if needed for latest BDA APIs
    });
    
    // --- Use Provider Framework for Custom Resource Invocation ---
    const bdaProjectProvider = new custom.Provider(this, 'BdaProjectProvider', {
        onEventHandler: bdaProjectHandlerFunction,
        logRetention: logs.RetentionDays.ONE_WEEK, // Optional: configure log retention
    });

    const bdaProjectResource = new cdk.CustomResource(this, 'BdaProjectResource', {
        serviceToken: bdaProjectProvider.serviceToken,
        properties: {
            ProjectName: projectName,
            ProjectDescription: projectDescription,
            // Add a timestamp or changing property if you need the lambda to re-run on updates
            // Timestamp: Date.now().toString() 
        }
    });

    // Retrieve the actual project ID from the Lambda output data
    this.projectId = bdaProjectResource.getAttString('ProjectId');
    
    // --- End BDA Project Handling ---


    // Create role with Bedrock permissions needed by OTHER Lambdas
    const bedrockRole = new iam.Role(this, 'BedrockAccessRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonBedrockFullAccess') 
      ]
    });
    
    // Update BDA permissions policy to use the dynamically retrieved projectId
    bedrockRole.addToPolicy(new iam.PolicyStatement({
        actions: [
            "bedrock-data-automation:ListBlueprints",
            "bedrock-data-automation:GetBlueprint",
            "bedrock-data-automation:CreateBlueprint",
            "bedrock-data-automation:UpdateBlueprint",
            "bedrock-data-automation:DeleteBlueprint",
            "bedrock-data-automation:StartDataAutomationExecution",
            "bedrock-data-automation:GetDataAutomationExecution",
            "bedrock-data-automation:ListTagsForResource"
        ],
        resources: [
                    // Use the projectId obtained from the custom resource
                    `arn:aws:bedrock-data-automation:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:project/${this.projectId}`,
                    `arn:aws:bedrock-data-automation:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:project/${this.projectId}/blueprint/*`,
                    `arn:aws:bedrock-data-automation:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:project/${this.projectId}/execution/*`
                   ],
        effect: iam.Effect.ALLOW,
    }));
     bedrockRole.addToPolicy(new iam.PolicyStatement({ 
        actions: [ "bedrock-data-automation:ListProjects" ], 
        resources: ["*"],
        effect: iam.Effect.ALLOW,
    }));

    // Pass the actual projectId to the environment variables
    const lambdaEnvironment = {
      "BDA_PROJECT_ID": this.projectId
    };

    // Create the blueprint Lambda function if required
    if (isBlueprintRequired) {
      this.bdaBlueprintFunction = new PythonFunction(this, 'BlueprintFunction', {
        functionName: `bda-blueprint-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        entry: path.join(__dirname, "../../../src/backend/documentprocessing/lambda/blueprint_creation"),
        index: "blueprint_creation.py",
        handler: "lambda_handler",
        runtime: Runtime.PYTHON_3_11,
        timeout: Duration.minutes(5),
        memorySize: 512,
        role: bedrockRole,
        layers: [props.layerBoto],
        environment: lambdaEnvironment // Use common environment
      });

      // Explicitly grant EventBridge permission to invoke this Lambda
      // Note: The sourceArn might need adjustment depending on actual EventBridge rule naming
      this.bdaBlueprintFunction.addPermission('EventBridgeInvokePermission', {
        principal: new iam.ServicePrincipal('events.amazonaws.com'),
        action: 'lambda:InvokeFunction',
        sourceArn: `arn:aws:events:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:rule/*BlueprintCreationRule*` // Adjust wildcard/name as needed
      });

    }

    // Create the invocation Lambda function
    this.bdaInvocationFunction = new PythonFunction(this, 'InvocationFunction', {
       functionName: `bda-invoke-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
       entry: path.join(__dirname, "../../../src/backend/documentprocessing/lambda/processing"),
       index: "processing.py",
       handler: "lambda_handler",
       runtime: Runtime.PYTHON_3_11,
       timeout: Duration.minutes(15),
       memorySize: 1024,
       role: bedrockRole,
       environment: {
        ...lambdaEnvironment, // Spread common environment
        "INPUT_BUCKET": props.bdaInputBucketName,
        "OUTPUT_BUCKET": props.bdaOutputBucketName,
      }
    });

    // Create the results Lambda function
    this.bdaResultsFunction = new lambda.Function(this, 'ResultsFunction', {
      functionName: `bda-results-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      code: lambda.Code.fromAsset(path.join(__dirname, "../../../src/backend/documentprocessing/lambda/processing")),
      handler: "processing.get_results",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(2),
      memorySize: 512,
      role: bedrockRole,
      environment: {
         ...lambdaEnvironment, // Spread common environment
        "OUTPUT_BUCKET": props.bdaOutputBucketName,
      }
    });

    // Create the status check Lambda function if required
    if (isStatusRequired) {
      this.bdaResultStatusFunction = new lambda.Function(this, 'StatusFunction', {
        functionName: `bda-status-fn-${cdk.Names.uniqueId(this).substring(0, 8)}`,
        code: lambda.Code.fromAsset(path.join(__dirname, "../../../src/backend/documentprocessing/lambda/processing")),
        handler: "processing.check_status",
        runtime: Runtime.PYTHON_3_11,
        timeout: Duration.minutes(2),
        memorySize: 512,
        role: bedrockRole,
         environment: lambdaEnvironment // Use common environment
      });
    }

    // Grant S3 read access to Invocation Lambda for input bucket
    const inputBucket = s3.Bucket.fromBucketName(this, 'InputBucketImport', props.bdaInputBucketName);
    inputBucket.grantRead(this.bdaInvocationFunction);

    // Grant S3 read/write access to Invocation and Results Lambda for output bucket
    const outputBucket = s3.Bucket.fromBucketName(this, 'OutputBucketImport', props.bdaOutputBucketName);
    outputBucket.grantReadWrite(this.bdaInvocationFunction);
    outputBucket.grantRead(this.bdaResultsFunction);
    if (this.bdaBlueprintFunction) { // Grant read access if blueprint function exists and needs access (e.g. to read schema examples)
        outputBucket.grantRead(this.bdaBlueprintFunction);
    }
     if (this.bdaResultStatusFunction) { // Grant read access if status function exists
        outputBucket.grantRead(this.bdaResultStatusFunction);
    }

  }
}

// Define a custom EventBridge to Lambda pattern (Keep as is)
class EventbridgeToLambda extends Construct {
// ... existing code ...
}

interface BedrockDocumentProcessingStackProps extends StackProps {
// ... existing code ...
}

// Export the class (Keep as is)
export class BedrockDocumentProcessingStack extends Stack {
// ... existing code ...
}
