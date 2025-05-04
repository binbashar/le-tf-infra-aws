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
import { Runtime, LayerVersion, Code } from "aws-cdk-lib/aws-lambda";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as sqs from "aws-cdk-lib/aws-sqs";
import * as cdk from "aws-cdk-lib/core";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

interface BedrockText2SqlAgentsStackProps extends StackProps {
  AGENT_KB: bedrock.KnowledgeBase | null;
  LAYER_BOTO: PythonLayerVersion;
  LAYER_POWERTOOLS: PythonLayerVersion;
  LAYER_PYDANTIC: PythonLayerVersion;
  ATHENA_OUTPUT_BUCKET: s3.Bucket;
  ATHENA_DATA_BUCKET: s3.Bucket;
}

export class BedrockText2SqlAgentsStack extends Stack {
  public readonly AGENT: bedrock.Agent;
  public readonly AGENT_ALIAS: string;

  constructor(
    scope: Construct,
    id: string,
    props: BedrockText2SqlAgentsStackProps,
  ) {
    super(scope, id, props);

    // Common Layer for Athena utilities
    const athenaCommonLayer = new LayerVersion(this, "AthenaCommonLayer", {
      code: Code.fromAsset(
        path.join(__dirname, "../../backend/agents/lambda/text2sql/athena/common"),
      ),
      description: "Common utilities for Athena operations",
      compatibleRuntimes: [Runtime.PYTHON_3_11],
    });

    // Define a function to create Athena Lambdas - 1. query execution, 2. schema read
    function createAthenaLambdaRole(
      parentScope: Construct,
      roleId: string,
      athenaDataBucket: s3.Bucket,
      athenaOutputBucket: s3.Bucket,
    ): iam.Role {
      const stack = Stack.of(parentScope);
      const role = new iam.Role(parentScope, roleId, {
        assumedBy: new iam.ServicePrincipal("lambda.amazonaws.com"),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName(
            "service-role/AWSLambdaBasicExecutionRole",
          ),
        ],
      });

      role.addToPolicy(
        new iam.PolicyStatement({
          actions: [
            "athena:StartQueryExecution",
            "athena:GetQueryExecution",
            "athena:GetQueryResults",
          ],
          resources: [
            `arn:aws:athena:${stack.region}:${stack.account}:workgroup/primary`,
          ],
        }),
      );

      role.addToPolicy(
        new iam.PolicyStatement({
          actions: [
            "glue:GetDatabase",
            "glue:GetTable",
            "glue:GetTables",
            "glue:GetPartitions",
          ],
          resources: [
            `arn:aws:glue:${stack.region}:${stack.account}:catalog`,
            `arn:aws:glue:${stack.region}:${stack.account}:database/*`,
            `arn:aws:glue:${stack.region}:${stack.account}:table/*`,
          ],
        }),
      );

      role.addToPolicy(
        new iam.PolicyStatement({
          actions: [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject",
          ],
          resources: [
            athenaDataBucket.bucketArn,
            `${athenaDataBucket.bucketArn}/*`,
            athenaOutputBucket.bucketArn,
            `${athenaOutputBucket.bucketArn}/*`,
          ],
        }),
      );

      return role;
    }

    // Define a function to create Agent action group Lambdas
    function createLambdaFunction(
      parentScope: Construct,
      lambdaId: string,
      lambdaProps: {
        entry: string;
        role?: iam.Role;
        layers?: PythonLayerVersion[];
        environment?: { [key: string]: string };
        deadLetterQueue?: sqs.Queue;
      },
    ): PythonFunction {
      // Extract the file name, which is set to be same as the directory base name
      const fileName = path.basename(lambdaProps.entry);
      return new PythonFunction(parentScope, lambdaId, {
        functionName: `${path.parse(fileName).name}-${id}`,
        entry: lambdaProps.entry,
        index: fileName + ".py",
        handler: "lambda_handler", // The handler name must be lambda_handler
        runtime: Runtime.PYTHON_3_11,
        timeout: Duration.minutes(5),
        memorySize: 256,
        environment: lambdaProps.environment,
        layers: lambdaProps.layers,
        role: lambdaProps.role,
        deadLetterQueue: lambdaProps.deadLetterQueue,
      });
    }

    // Define a function to create a Bedrock Agent action group
    function createAgentActionGroup(
      parentScope: Construct,
      agentId: string,
      agentProps: {
        actionGroupName: string;
        description: string;
        lambda: PythonFunction;
        openApiPath: string;
      },
    ): AgentActionGroup {
      return new AgentActionGroup(parentScope, agentId, {
        actionGroupName: agentProps.actionGroupName,
        description: agentProps.description,
        actionGroupExecutor: {
          lambda: agentProps.lambda,
        },
        actionGroupState: "ENABLED",
        apiSchema: bedrock.ApiSchema.fromAsset(
          // openapi.json schema must be defined and stored under the path
          path.join(
            __dirname,
            "../../backend/agents/lambda/text2sql/athena",
            agentProps.openApiPath,
            "openapi.json",
          ),
        ),
      });
    }

    // * Export system prompt - update prompt files from local
    const instruction = readFileSync(
      path.join(__dirname, "../../prompt/instruction/text2sql", "instruction.txt"), // text2sql
      "utf8",
    );
    const orchestration = readFileSync(
      path.join(
        __dirname,
        "../../prompt/orchestration/text2sql/claude/sonnet3.5", // Using Claude Sonnet 3.5 prompt
        "orchestration_prompt.txt",
      ),
      "utf8",
    );

    // Create Bedrock Agent
    const bedrockAgent = new bedrock.Agent(this, "AthenaAgent", {
      name: (cdk.Stack.of(this) + "-" + "AthenaAgent").replace("/", "-"),
      foundationModel:
        bedrock.BedrockFoundationModel.ANTHROPIC_CLAUDE_3_5_SONNET_V2_0,
      shouldPrepareAgent: true,
      enableUserInput: true,
      instruction:
        "You are " +
        this.node.tryGetContext("custom:agentName") +
        ", a SQL analyst AI created specifically for " +
        this.node.tryGetContext("custom:companyName") +
        ". If Human says Hello, Great the human with your name." +
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

    // Create IAM role for Athena Schema Reader Lambda
    const athenaSchemaReaderRole = createAthenaLambdaRole(
      this,
      "AthenaSchemaReaderRole",
      props.ATHENA_DATA_BUCKET,
      props.ATHENA_OUTPUT_BUCKET,
    );

    // Create Athena Schema Reader Lambda
    const athenaSchemaReaderLambda = createLambdaFunction(
      this,
      "AthenaSchemaReaderLambda",
      {
        entry: path.join(
          "src/backend/agents/lambda/text2sql/athena",
          "athena_schema_reader",
        ),
        role: athenaSchemaReaderRole,
        layers: [
          props.LAYER_BOTO,
          props.LAYER_POWERTOOLS,
          props.LAYER_PYDANTIC,
          athenaCommonLayer,
        ],
        environment: {
          S3_OUTPUT: props.ATHENA_OUTPUT_BUCKET.bucketName,
          S3_DATA_BUCKET: props.ATHENA_DATA_BUCKET.bucketName,
        },
      },
    );

    // Create DLQ for Athena Query Lambda
    const athenaQueryLambdaDLQ = new sqs.Queue(this, "AthenaQueryLambdaDLQ", {
      queueName: `AthenaQueryLambdaDLQs-${this.account}-${this.region}`,
      encryption: sqs.QueueEncryption.SQS_MANAGED,
      enforceSSL: true,
    });

    // Create IAM role for Athena Query Execution Lambda
    const athenaQueryLambdaRole = createAthenaLambdaRole(
      this,
      "AthenaQueryLambdaRole",
      props.ATHENA_DATA_BUCKET,
      props.ATHENA_OUTPUT_BUCKET,
    );
    athenaQueryLambdaRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ["sqs:SendMessage"],
        resources: [athenaQueryLambdaDLQ.queueArn],
      }),
    );

    // Create Athena Query Execution Lambda
    const athenaQueryLambda = createLambdaFunction(this, "AthenaQueryLambda", {
      entry: path.join(
        "src/backend/agents/lambda/text2sql/athena",
        "athena_actions",
      ),
      role: athenaQueryLambdaRole,
      layers: [
        props.LAYER_BOTO,
        props.LAYER_POWERTOOLS,
        props.LAYER_PYDANTIC,
        athenaCommonLayer,
      ],
      environment: {
        S3_OUTPUT: props.ATHENA_OUTPUT_BUCKET.bucketName,
        S3_DATA_BUCKET: props.ATHENA_DATA_BUCKET.bucketName,
      },
      deadLetterQueue: athenaQueryLambdaDLQ,
    });

    // Grant permissions to the Lambda function
    props.ATHENA_DATA_BUCKET.grantReadWrite(
      athenaQueryLambda,
      athenaSchemaReaderLambda,
    );
    props.ATHENA_OUTPUT_BUCKET.grantReadWrite(
      athenaQueryLambda,
      athenaSchemaReaderLambda,
    );

    // Add Athena Query Action Group
    const athenaQueryActionGroup = createAgentActionGroup(
      this,
      "AthenaQueryActionGroup",
      {
        actionGroupName: "athena-query",
        description:
          "This action group is used to query information about data",
        lambda: athenaQueryLambda,
        openApiPath: "athena_actions",      },
    );
    bedrockAgent.addActionGroup(athenaQueryActionGroup);

    // Add Athena Schema Reader Action Group
    const athenaSchemaReaderActionGroup = createAgentActionGroup(
      this,
      "AthenaSchemaReaderActionGroup",
      {
        actionGroupName: "athena-schema-reader",
        description: "This action group is used to read schema from Athena",
        lambda: athenaSchemaReaderLambda,
        openApiPath: "athena_schema_reader",
      },
    );
    bedrockAgent.addActionGroup(athenaSchemaReaderActionGroup);

    // Create Bedrock Agent Alias
    const athenaAgentAlias = new bedrock.AgentAlias(this, "AthenaAgentAlias", {
      agentId: bedrockAgent.agentId,
      aliasName: "latest",
    });
    this.AGENT_ALIAS = athenaAgentAlias.aliasId;

    // Create CloudWatch Dashboard for Bedrock
    const bddashboard = new BedrockCwDashboard(
      this,
      "BedrockDashboardConstructText2sql",
      {
        dashboardName: "BinbashGenAIWorkshopDashboardText2Sql",
      },
    );

    // provides monitoring of all models
    bddashboard.addAllModelsMonitoring();

    // provides monitoring for a specific model with on-demand pricing calculation
    // pricing details are available here: https://aws.amazon.com/bedrock/pricing/
    bddashboard.addModelMonitoring(
      "Claude Sonnet 3.5 v2",
      // Claude Sonnet 3.5 ARN (us-west-2) - Update region in ARN if necessary
      "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
      {
        inputTokenPrice: 0.003, // On-demand Price per 1K input tokens
        outputTokenPrice: 0.015, // Price per 1K output tokens
      },
    );

    const knowledgeBase = props.AGENT_KB;
    if (knowledgeBase) {
      // Add Knowledge Base to the agent
      bedrockAgent.addKnowledgeBase(knowledgeBase);

      // Embeddings model monitoring specific to Knowledge Base scenario
      bddashboard.addModelMonitoring(
        "Amazon Titan Text Embeddings V2",
        "amazon.titan-embed-text-v2:0",
        {
          inputTokenPrice: 0.00002,
          outputTokenPrice: 0, // N/A for Amazon Titan Text Embeddings V1 and V2
        },
      );
    }

    // Suppress CDK-nag warnings
    NagSuppressions.addResourceSuppressions(
      athenaQueryLambdaDLQ,
      [
        {
          id: "AwsSolutions-SQS3",
          reason: "DLQ does not require server-side encryption with KMS",
        },
      ],
      true,
    );
  }
}
