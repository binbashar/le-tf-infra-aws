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
import * as custom from "aws-cdk-lib/custom-resources";
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
 * It's a wrapper around the blueprint creation, document processing, and results
 * functionality needed for KYB document processing.
 */
class BedrockDataAutomation extends Construct {
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
        environment: {
          "BDA_PROJECT_ID": projectName
        }
      });

      // Explicitly grant EventBridge permission to invoke this Lambda
      this.bdaBlueprintFunction.addPermission('EventBridgeInvokePermission', {
        principal: new iam.ServicePrincipal('events.amazonaws.com'),
        action: 'lambda:InvokeFunction',
        sourceArn: `arn:aws:events:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:rule/BinbashWorkshopDocumentPr-KybBlueprintCreationRule*` // Be specific if possible, use wildcard if name varies
      });

    } else {
      // Create a placeholder Lambda if not required
      this.bdaBlueprintFunction = new lambda.Function(this, 'BlueprintFunction', {
        functionName: `bda-blueprint-placeholder-${cdk.Names.uniqueId(this).substring(0, 8)}`,
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
      entry: path.join(__dirname, "../../../src/backend/documentprocessing/lambda/processing"),
      index: "processing.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(15),
      memorySize: 1024,
      role: bedrockRole,
      environment: {
        "INPUT_BUCKET": props.bdaInputBucketName,
        "OUTPUT_BUCKET": props.bdaOutputBucketName,
        "BDA_PROJECT_ID": projectName
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
        "OUTPUT_BUCKET": props.bdaOutputBucketName
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

// Define a custom EventBridge to Lambda pattern
class EventbridgeToLambda extends Construct {
  constructor(scope: Construct, id: string, props: {
    existingLambdaObj: any,
    eventRuleProps: events.RuleProps
  }) {
    super(scope, id);
    
    // Create EventBridge rule
    const rule = new events.Rule(this, 'Rule', props.eventRuleProps);
    
    // Add Lambda as target
    rule.addTarget(new targets.LambdaFunction(props.existingLambdaObj));
  }
}

interface BedrockDocumentProcessingStackProps extends StackProps {
  // Using string properties to avoid circular dependencies
  INPUT_BUCKET_NAME: string;
  OUTPUT_BUCKET_NAME: string;
  METADATA_TABLE_NAME: string;
  LAYER_BOTO: PythonLayerVersion;
  LAYER_POWERTOOLS: PythonLayerVersion;
  LAYER_PYDANTIC: PythonLayerVersion;
  KYB_ENABLED?: boolean; // Optional flag to enable KYB workflow
}

export class BedrockDocumentProcessingStack extends Stack {
  public readonly BEDROCK_DATA_AUTOMATION_PROJECT_ID: string;
  public readonly AGENT: bedrock.Agent;
  public readonly AGENT_ALIAS: string;
  public readonly documentProcessingStateMachine: stepfunctions.StateMachine;
  public readonly documentProcessingFunction: PythonFunction;
  public readonly documentSplitterFunction: PythonFunction;
  public readonly documentValidationFunction: PythonFunction;
  private readonly bdaConstruct: BedrockDataAutomation;

  constructor(
    scope: Construct,
    id: string,
    props: BedrockDocumentProcessingStackProps,
  ) {
    super(scope, id, props);

    // Generate a unique project ID based on the stack name
    this.BEDROCK_DATA_AUTOMATION_PROJECT_ID = `bda-project-${cdk.Names.uniqueId(this)}`.toLowerCase();

    // Get bucket and table references from names
    const inputBucket = s3.Bucket.fromBucketName(this, 'InputBucket', props.INPUT_BUCKET_NAME);
    const outputBucket = s3.Bucket.fromBucketName(this, 'OutputBucket', props.OUTPUT_BUCKET_NAME);
    const metadataTable = dynamodb.Table.fromTableName(this, 'MetadataTable', props.METADATA_TABLE_NAME);

    // Create Bedrock Data Automation construct with KYB support
    this.bdaConstruct = new BedrockDataAutomation(this, 'BedrockDataAutomation', {
      bdaInputBucketName: props.INPUT_BUCKET_NAME,
      bdaOutputBucketName: props.OUTPUT_BUCKET_NAME,
      isProjectRequired: true,
      isBlueprintRequired: true,
      isStatusRequired: true,
      projectName: this.BEDROCK_DATA_AUTOMATION_PROJECT_ID,
      layerBoto: props.LAYER_BOTO,
      isKYBEnabled: props.KYB_ENABLED ?? false
    });
    
    // Create document processing Lambda
    this.documentProcessingFunction = new PythonFunction(this, "DocumentProcessingFunction", {
      functionName: `DocProcess-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      entry: path.join(__dirname, "../../backend/documentprocessing/lambda/processing"),
      index: "processing.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(15),
      memorySize: 1024,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
      ],
      environment: {
        "METADATA_TABLE": props.METADATA_TABLE_NAME,
        "OUTPUT_BUCKET": props.OUTPUT_BUCKET_NAME,
        "BDA_PROJECT_ID": this.BEDROCK_DATA_AUTOMATION_PROJECT_ID,
      },
      bundling: {
        command: [
          'pip', 'install', 'fastjsonschema', '-t', '/asset-output'
        ]
      }
    });
    
    // Create document splitter Lambda
    this.documentSplitterFunction = new PythonFunction(this, "DocumentSplitterFunction", {
      functionName: `DocSplitter-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      entry: path.join(__dirname, "../../backend/documentprocessing/lambda/document_splitter"),
      index: "document_splitter.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(5),
      memorySize: 512,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
      ],
      environment: {
        "INPUT_BUCKET": props.INPUT_BUCKET_NAME,
        "OUTPUT_BUCKET": props.OUTPUT_BUCKET_NAME,
        "METADATA_TABLE": props.METADATA_TABLE_NAME,
      },
      bundling: {
        command: [
          'pip', 'install', 'PyMuPDF', '-t', '/asset-output'
        ]
      }
    });

    // Grant permissions to the Lambda functions using imported bucket references
    inputBucket.grantRead(this.documentProcessingFunction);
    outputBucket.grantReadWrite(this.documentProcessingFunction);
    metadataTable.grantReadWriteData(this.documentProcessingFunction);
    
    inputBucket.grantRead(this.documentSplitterFunction);
    outputBucket.grantReadWrite(this.documentSplitterFunction);
    metadataTable.grantReadWriteData(this.documentSplitterFunction);
    
    // Create IAM role for Bedrock access
    const bedrockRole = new iam.Role(this, 'BedrockAccessRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole')
      ]
    });
    
    bedrockRole.addToPolicy(new iam.PolicyStatement({
      actions: [
        'bedrock:*',
      ],
      resources: ['*'],
    }));
    
    this.documentProcessingFunction.role?.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonBedrockFullAccess')
    );
    
    // Read KYB-specific instruction and orchestration prompts
    const instruction = readFileSync(
      path.join(__dirname, "../../prompt/instruction/documentprocessing", props.KYB_ENABLED ? "kyb_instruction.txt" : "instruction.txt"),
      "utf8",
    );
    const orchestration = JSON.parse(readFileSync(
      path.join(__dirname, "../../prompt/orchestration/documentprocessing/claude/sonnet3.5", props.KYB_ENABLED ? "kyb_orchestration_prompt.txt" : "orchestration_prompt.txt"),
      "utf8",
    ));

    // Create Bedrock Agent with KYB support
    const bedrockAgent = new bedrock.Agent(this, "DocumentProcessingAgent", {
      name: (cdk.Stack.of(this) + "-" + (props.KYB_ENABLED ? "KYBAgent" : "DocumentProcessingAgent")).replace("/", "-"),
      foundationModel: bedrock.BedrockFoundationModel.ANTHROPIC_CLAUDE_3_5_SONNET_V2_0,
      shouldPrepareAgent: true,
      enableUserInput: true,
      instruction: "You are " +
        this.node.tryGetContext("custom:agentName") +
        ", a " + (props.KYB_ENABLED ? "KYB document processing" : "document processing") + " AI created specifically for " +
        this.node.tryGetContext("custom:companyName") +
        ". If Human says Hello, greet the human with your name." +
        "\n" +
        instruction,
      promptOverrideConfiguration: {
        promptConfigurations: [
          {
            promptType: bedrock.PromptType.ORCHESTRATION,
            parserMode: bedrock.ParserMode.DEFAULT,
            inferenceConfiguration: {
              temperature: 0,
              topP: 1,
              topK: 250,
              maximumLength: 2048,
              stopSequences: ["</invoke>", "</e>", "</answer>"],
            },
            basePromptTemplate: JSON.stringify(orchestration),
            promptCreationMode: PromptCreationMode.OVERRIDDEN,
            promptState: PromptState.ENABLED,
          },
        ],
      },
    });
    this.AGENT = bedrockAgent;

    // Create document validation Lambda
    this.documentValidationFunction = new PythonFunction(this, "DocumentValidationFunction", {
      functionName: `DocValidation-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      entry: path.join(__dirname, "../../backend/documentprocessing/lambda/validation"),
      index: "validation.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(5),
      memorySize: 512,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
      ],
      environment: {
        "OUTPUT_BUCKET": props.OUTPUT_BUCKET_NAME,
        "METADATA_TABLE": props.METADATA_TABLE_NAME,
      }
    });
    
    // Grant permissions to the validation Lambda
    metadataTable.grantReadWriteData(this.documentValidationFunction);

    // Create Agent Action Groups for processing and validation
    const documentProcessingActionGroup = new AgentActionGroup(this, "DocumentProcessingActionGroup", {
      actionGroupName: "document-processing",
      description: "Process documents using Amazon Bedrock Data Automation",
      actionGroupExecutor: {
        lambda: this.documentProcessingFunction,
      },
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/processing/openapi.json"),
      ),
    });

    const documentSplitterActionGroup = new AgentActionGroup(this, "DocumentSplitterActionGroup", {
      actionGroupName: "document-splitting",
      description: "Split documents into pages for processing",
      actionGroupExecutor: {
        lambda: this.documentSplitterFunction,
      },
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/document_splitter/openapi.json"),
      ),
    });

    const documentValidationActionGroup = new AgentActionGroup(this, "DocumentValidationActionGroup", {
      actionGroupName: "document-validation",
      description: "Validate processed documents",
      actionGroupExecutor: {
        lambda: this.documentValidationFunction,
      },
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/validation/openapi.json"),
      ),
    });

    // Add BDA action groups for blueprint management and data processing
    const bdaBlueprintActionGroup = new AgentActionGroup(this, "BdaBlueprintActionGroup", {
      actionGroupName: "blueprint-management",
      description: "Create and manage Bedrock Data Automation blueprints",
      actionGroupExecutor: {
        lambda: this.bdaConstruct.bdaBlueprintFunction,
      },
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/blueprint_creation/openapi.json"),
      ),
    });

    // Add KYB Agent action groups
    if (props.KYB_ENABLED) {
      const kybProcessingActionGroup = new AgentActionGroup(this, "KYBProcessingActionGroup", {
        actionGroupName: "kyb-processing",
        description: "Process KYB documents using Amazon Bedrock Data Automation",
        actionGroupExecutor: {
          lambda: this.documentProcessingFunction,
        },
        apiSchema: bedrock.ApiSchema.fromAsset(
          path.join(__dirname, "../../backend/agents/lambda/kyb_agent/openapi.json"),
        ),
      });

      const kybValidationActionGroup = new AgentActionGroup(this, "KYBValidationActionGroup", {
        actionGroupName: "kyb-validation",
        description: "Validate KYB documents",
        actionGroupExecutor: {
          lambda: this.documentValidationFunction,
        },
        apiSchema: bedrock.ApiSchema.fromAsset(
          path.join(__dirname, "../../backend/documentprocessing/lambda/validation/openapi.json"),
        ),
      });

      // Add KYB action groups to agent
      bedrockAgent.addActionGroup(kybProcessingActionGroup);
      bedrockAgent.addActionGroup(kybValidationActionGroup);
    }

    // Add action groups to agent - limit to the most essential ones to stay under quota
    bedrockAgent.addActionGroup(documentProcessingActionGroup);   // Keep core processing functionality
    //bedrockAgent.addActionGroup(documentSplitterActionGroup);     // Needed for document splitting
    bedrockAgent.addActionGroup(bdaBlueprintActionGroup);         // Needed for blueprint management
    // bedrockAgent.addActionGroup(documentValidationActionGroup); // Temporarily disable validation to stay under the API limit
    
    // Comment out lower priority action groups to stay under the limit
    // bedrockAgent.addActionGroup(documentValidationActionGroup); // Temporarily disable validation

    // Create agent alias and store the name
    this.AGENT_ALIAS = "latest";
    const alias = bedrockAgent.addAlias({
      aliasName: this.AGENT_ALIAS
    });

    // Invoke KYB blueprint creation using EventBridge to Lambda pattern
    new EventbridgeToLambda(this, "KybBlueprintCreation", {
      existingLambdaObj: this.bdaConstruct.bdaBlueprintFunction,
      eventRuleProps: {
        eventPattern: {
          source: ["custom.bedrock.blueprint"],
          detailType: ["Initialize KYB Blueprints"],
        },
      },
    });

    // Create a custom resource to initialize KYB blueprints during deployment
    const eventHelperFunction = new lambda.Function(this, 'EventBridgeHelperFunction', {
      runtime: lambda.Runtime.NODEJS_16_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
const AWS = require('aws-sdk');
const eventbridge = new AWS.EventBridge();
const https = require('https');
const url = require('url');

exports.handler = async function(event, context) {
  console.log("Event received:", JSON.stringify(event, null, 2));
  
  // For all event types, always respond to CloudFormation
  try {
    if (event.RequestType === 'Create' || event.RequestType === 'Update') {
      try {
        const result = await eventbridge.putEvents({
          Entries: [{
            Source: "custom.bedrock.blueprint",
            DetailType: "Initialize KYB Blueprints",
            Detail: JSON.stringify({
              operation: 'create_blueprints',
              project_id: event.ResourceProperties.projectId
            })
          }]
        }).promise();
        
        console.log("Put events result:", JSON.stringify(result, null, 2));
        await sendResponse(event, context, 'SUCCESS');
      } catch (err) {
        console.error("Error putting events:", err);
        await sendResponse(event, context, 'FAILED', err.message);
      }
    } else if (event.RequestType === 'Delete') {
      // Just return success for Delete
      await sendResponse(event, context, 'SUCCESS');
    }
  } catch (err) {
    console.error('Error in Lambda handler:', err);
    await sendResponse(event, context, 'FAILED', err.message);
  }
};

// Function to send response back to CloudFormation
async function sendResponse(event, context, responseStatus, reason) {
  const responseBody = JSON.stringify({
    Status: responseStatus,
    Reason: reason || 'See CloudWatch logs',
    PhysicalResourceId: event.LogicalResourceId || context.logStreamName,
    StackId: event.StackId,
    RequestId: event.RequestId,
    LogicalResourceId: event.LogicalResourceId,
    NoEcho: false,
    Data: { ProjectId: event.ResourceProperties.projectId }
  });
  
  console.log("Sending response:", responseBody);
  
  // CloudFormation waits for this response via the pre-signed URL
  return new Promise((resolve, reject) => {
    // If we're running locally, just return
    if (!event.ResponseURL) {
      console.log('No ResponseURL found. Likely running locally.');
      resolve({ statusCode: 200, body: responseBody });
      return;
    }
    
    const parsedUrl = url.parse(event.ResponseURL);
    const options = {
      hostname: parsedUrl.hostname,
      port: 443,
      path: parsedUrl.path,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': responseBody.length
      }
    };
    
    const request = https.request(options, (response) => {
      console.log(\`Status code: \${response.statusCode}\`);
      resolve(response);
    });
    
    request.on('error', (error) => {
      console.log(\`Send response error: \${error}\`);
      reject(error);
    });
    
    request.write(responseBody);
    request.end();
  });
}
      `),
      timeout: Duration.minutes(1),
      environment: {
        PROJECT_ID: this.BEDROCK_DATA_AUTOMATION_PROJECT_ID
      }
    });
    
    // Grant the Lambda permission to put events to EventBridge
    eventHelperFunction.addToRolePolicy(new iam.PolicyStatement({
      actions: ['events:PutEvents'],
      resources: ['*']
    }));
    
    // Create the custom resource backed by the Lambda
    const blueprintInitializer = new custom.Provider(this, 'BlueprintInitializerProvider', {
      onEventHandler: eventHelperFunction
    });
    
    // Use the custom resource provider
    new cdk.CustomResource(this, 'BlueprintInitializer', {
      serviceToken: blueprintInitializer.serviceToken,
      properties: {
        projectId: this.BEDROCK_DATA_AUTOMATION_PROJECT_ID,
        uniqueId: Date.now().toString() // To force update
      }
    });

    // Create CloudWatch dashboard
    new BedrockCwDashboard(this, "BedrockCwDashboard", {
      dashboardName: "BedrockDocumentProcessingDashboard",
    });

    // Suppress CDK Nag warnings
    NagSuppressions.addResourceSuppressions(
      [bedrockAgent.role],
      [
        {
          id: "AwsSolutions-IAM5",
          reason: "Wildcard permissions are required for Bedrock Data Automation operations",
        },
      ],
    );
  }
}
