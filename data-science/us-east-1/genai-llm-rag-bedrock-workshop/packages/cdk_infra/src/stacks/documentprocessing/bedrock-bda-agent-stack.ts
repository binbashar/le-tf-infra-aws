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
  BedrockDataAutomation
} from "aws-bedrock-data-automation";
import { Stack, StackProps, Duration } from "aws-cdk-lib";
import * as iam from "aws-cdk-lib/aws-iam";
import { Runtime, LayerVersion, Code } from "aws-cdk-lib/aws-lambda";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as sqs from "aws-cdk-lib/aws-sqs";
import * as cdk from "aws-cdk-lib/core";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";
import {
  AgentActionGroup,
  PromptCreationMode,
  PromptState,
} from "@cdklabs/generative-ai-cdk-constructs/lib/cdk-lib/bedrock";

interface BedrockDocumentProcessingStackProps extends StackProps {
  INPUT_BUCKET: s3.Bucket;
  OUTPUT_BUCKET: s3.Bucket;
  LAYER_BOTO: PythonLayerVersion;
  LAYER_POWERTOOLS: PythonLayerVersion;
  LAYER_PYDANTIC: PythonLayerVersion;
}

export class BedrockDocumentProcessingStack extends Stack {
  public readonly BEDROCK_DATA_AUTOMATION: BedrockDataAutomation;
  public readonly AGENT: bedrock.Agent;
  public readonly AGENT_ALIAS: string;

  constructor(
    scope: Construct,
    id: string,
    props: BedrockDocumentProcessingStackProps,
  ) {
    super(scope, id, props);

    // Create Bedrock Data Automation stack
    const bedrockDataAutomation = new BedrockDataAutomation(this, "DocumentProcessing", {
      inputBucket: props.INPUT_BUCKET,
      outputBucket: props.OUTPUT_BUCKET,
    });

    this.BEDROCK_DATA_AUTOMATION = bedrockDataAutomation;

    // Read instruction and orchestration prompts
    const instruction = readFileSync(
      path.join(__dirname, "../../prompt/instruction/documentprocessing", "instruction.txt"),
      "utf8",
    );
    const orchestration = readFileSync(
      path.join(__dirname, "../../prompt/orchestration/documentprocessing/claude/sonnet3.5", "orchestration_prompt.txt"),
      "utf8",
    );

    // Create Bedrock Agent for document processing validation
    const bedrockAgent = new bedrock.Agent(this, "DocumentProcessingAgent", {
      name: (cdk.Stack.of(this) + "-" + "DocumentProcessingAgent").replace("/", "-"),
      foundationModel: bedrock.BedrockFoundationModel.ANTHROPIC_CLAUDE_3_5_SONNET_V1_0,
      shouldPrepareAgent: true,
      enableUserInput: true,
      instruction: "You are " +
        this.node.tryGetContext("custom:agentName") +
        ", a document processing validation AI created specifically for " +
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
              stopSequences: ["</invoke>", "</error>", "</answer>"],
            },
            basePromptTemplate: orchestration,
            promptCreationMode: PromptCreationMode.OVERRIDDEN,
            promptState: PromptState.ENABLED,
          },
        ],
      },
    });
    this.AGENT = bedrockAgent;

    // Create Lambda function for document validation
    const documentValidationLambda = new PythonFunction(this, "DocumentValidationLambda", {
      functionName: "DocumentProcessingValidation",
      entry: path.join(__dirname, "../../backend/documentprocessing/lambda/validation"),
      index: "validation.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(5),
      memorySize: 256,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
      ],
      environment: {
        INPUT_BUCKET: props.INPUT_BUCKET.bucketName,
        OUTPUT_BUCKET: props.OUTPUT_BUCKET.bucketName,
      },
    });

    // Create IAM roles for Lambda functions
    const documentProcessingRole = new iam.Role(this, "DocumentProcessingRole", {
      assumedBy: new iam.ServicePrincipal("lambda.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName(
          "service-role/AWSLambdaBasicExecutionRole",
        ),
      ],
      inlinePolicies: {
        s3Access: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket",
              ],
              resources: [
                props.INPUT_BUCKET.bucketArn,
                `${props.INPUT_BUCKET.bucketArn}/*`,
                props.OUTPUT_BUCKET.bucketArn,
                `${props.OUTPUT_BUCKET.bucketArn}/*`,
              ],
            }),
          ],
        }),
        bedrockAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ["bedrock:InvokeModel"],
              resources: ["*"],
            }),
          ],
        }),
      },
    });

    const blueprintCreationRole = new iam.Role(this, "BlueprintCreationRole", {
      assumedBy: new iam.ServicePrincipal("lambda.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName(
          "service-role/AWSLambdaBasicExecutionRole",
        ),
      ],
      inlinePolicies: {
        s3Access: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                "s3:PutObject",
                "s3:ListBucket",
              ],
              resources: [
                props.OUTPUT_BUCKET.bucketArn,
                `${props.OUTPUT_BUCKET.bucketArn}/*`,
              ],
            }),
          ],
        }),
        bedrockAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ["bedrock:InvokeModel"],
              resources: ["*"],
            }),
          ],
        }),
      },
    });

    // Create Lambda function for document processing
    const documentProcessingLambda = new PythonFunction(this, "DocumentProcessingLambda", {
      functionName: "DocumentProcessing",
      entry: path.join(__dirname, "../../backend/documentprocessing/lambda/processing"),
      index: "processing.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(5),
      memorySize: 256,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
      ],
      environment: {
        INPUT_BUCKET: props.INPUT_BUCKET.bucketName,
        OUTPUT_BUCKET: props.OUTPUT_BUCKET.bucketName,
      },
      role: documentProcessingRole,
    });

    // Create Lambda function for blueprint creation
    const blueprintCreationLambda = new PythonFunction(this, "BlueprintCreationLambda", {
      functionName: "BlueprintCreation",
      entry: path.join(__dirname, "../../backend/documentprocessing/lambda/blueprint_creation"),
      index: "blueprint_creation.py",
      handler: "lambda_handler",
      runtime: Runtime.PYTHON_3_11,
      timeout: Duration.minutes(5),
      memorySize: 256,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
      ],
      environment: {
        OUTPUT_BUCKET: props.OUTPUT_BUCKET.bucketName,
      },
      role: blueprintCreationRole,
    });

    // Grant necessary permissions
    props.INPUT_BUCKET.grantReadWrite(documentValidationLambda);
    props.OUTPUT_BUCKET.grantReadWrite(documentValidationLambda);
    props.INPUT_BUCKET.grantReadWrite(documentProcessingLambda);
    props.OUTPUT_BUCKET.grantReadWrite(documentProcessingLambda);
    props.OUTPUT_BUCKET.grantReadWrite(blueprintCreationLambda);

    // Create Agent Action Groups
    const documentValidationActionGroup = new AgentActionGroup(this, "DocumentValidationActionGroup", {
      actionGroupName: "document-validation",
      description: "This action group is used to validate document processing results",
      actionGroupExecutor: {
        lambda: documentValidationLambda,
      },
      actionGroupState: "ENABLED",
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/validation/openapi.json"),
      ),
    });

    const documentProcessingActionGroup = new AgentActionGroup(this, "DocumentProcessingActionGroup", {
      actionGroupName: "document-processing",
      description: "This action group is used to process documents",
      actionGroupExecutor: {
        lambda: documentProcessingLambda,
      },
      actionGroupState: "ENABLED",
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/processing/openapi.json"),
      ),
    });

    const blueprintCreationActionGroup = new AgentActionGroup(this, "BlueprintCreationActionGroup", {
      actionGroupName: "blueprint-creation",
      description: "This action group is used to create document processing blueprints",
      actionGroupExecutor: {
        lambda: blueprintCreationLambda,
      },
      actionGroupState: "ENABLED",
      apiSchema: bedrock.ApiSchema.fromAsset(
        path.join(__dirname, "../../backend/documentprocessing/lambda/blueprint_creation/openapi.json"),
      ),
    });

    // Add action groups to the agent
    bedrockAgent.addActionGroup(documentValidationActionGroup);
    bedrockAgent.addActionGroup(documentProcessingActionGroup);
    bedrockAgent.addActionGroup(blueprintCreationActionGroup);

    // Create Bedrock Agent Alias
    const documentProcessingAgentAlias = new bedrock.AgentAlias(this, "DocumentProcessingAgentAlias", {
      agentId: bedrockAgent.agentId,
      aliasName: "latest",
    });
    this.AGENT_ALIAS = documentProcessingAgentAlias.aliasId;

    // Create CloudWatch Dashboard for Bedrock
    const bddashboard = new BedrockCwDashboard(
      this,
      "BedrockDashboardConstructDocumentProcessing",
      {
        dashboardName: "PACEGenAIWorkshopBedrockDashboardDocumentProcessing",
      },
    );

    // provides monitoring of all models
    bddashboard.addAllModelsMonitoring();

    // provides monitoring for a specific model with on-demand pricing calculation
    bddashboard.addModelMonitoring(
      "Claude Sonnet 3.5 v2",
      "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
      {
        inputTokenPrice: 0.003,
        outputTokenPrice: 0.015,
      },
    );
  }
}
