/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as path from "path";
import {
  PythonFunction,
  PythonLayerVersion,
} from "@aws-cdk/aws-lambda-python-alpha";
import { bedrock } from "@cdklabs/generative-ai-cdk-constructs";
import { Stack, StackProps, Duration, RemovalPolicy } from "aws-cdk-lib";
import * as apigateway from "aws-cdk-lib/aws-apigateway";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";
import { ChatSummaryWithSessionId } from "../constructs/chat-summary-with-sessionid";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as cdk from 'aws-cdk-lib';

export interface BasicRestApiStackProps extends StackProps {
  env: cdk.Environment;
  LAYER_POWERTOOLS: PythonLayerVersion;
  LAYER_BOTO: PythonLayerVersion;
  LAYER_PYDANTIC: PythonLayerVersion;
  PREFIX: string;
  // Text2SQL specific properties
  AGENT?: bedrock.Agent;
  AGENT_ALIAS?: string;
  AGENT_KB?: bedrock.KnowledgeBase | null;
  // Document Processing specific properties
  DOCUMENT_INPUT_BUCKET?: s3.Bucket;
  DOCUMENT_OUTPUT_BUCKET?: s3.Bucket;
}

export class BasicRestApiStack extends Stack {
  public readonly SESSIONS_TABLE: dynamodb.Table;

  constructor(scope: Construct, id: string, props: BasicRestApiStackProps) {
    super(scope, id, props);

    // Prefix name for the api.
    const prefixName = props.PREFIX

    // * Amazon DynamoDB
    const sessionsTable = new dynamodb.Table(this, prefixName+"SessionsTable", {
      partitionKey: {
        name: "sessionId",
        type: dynamodb.AttributeType.STRING,
      },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      pointInTimeRecovery: true,
    });

    this.SESSIONS_TABLE = sessionsTable;

    // * AWS Lambda
    let basicRestApiLambdaDir = "src/backend/basic_rest_api/lambda";

    // Custom Lambda Authorizer for API Gateway
    const customAuthorizer = new PythonFunction(this, prefixName+"CustomAuthorizer", {
      entry: path.join(basicRestApiLambdaDir, "custom_authorizer"),
      runtime: lambda.Runtime.PYTHON_3_11,
      index: "custom_authorizer.py",
      handler: "lambda_handler",
      timeout: Duration.seconds(300),
      memorySize: 256,
      reservedConcurrentExecutions: 5,
      environment: {
        POWERTOOLS_LOG_LEVEL: "INFO",
        POWERTOOLS_SERVICE_NAME: "QnaAgentApi",
      },
      layers: [props.LAYER_POWERTOOLS, props.LAYER_BOTO],
    });

    // Lambda function role for log access, dynamodb read/write permissions, and bedrock invocation permissions.
    const lambdaRole = new iam.Role(this, prefixName+"CustomAuthorizerRole", {
      assumedBy: new iam.ServicePrincipal("lambda.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName(
          "service-role/AWSLambdaBasicExecutionRole",
        ),
      ],
      inlinePolicies: {
        dynamoDBAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
              ],
              resources: [sessionsTable.tableArn],
            }),
          ],
        }),
        ...(props.AGENT && {
          bedrockAgentAccess: new iam.PolicyDocument({
            statements: [
              new iam.PolicyStatement({
                effect: iam.Effect.ALLOW,
                actions: ["bedrock:InvokeAgent"],
                resources: [
                  props.AGENT.agentArn,
                  `arn:aws:bedrock:${this.region}:${this.account}:agent-alias/*`,
                ],
              }),
            ],
          }),
        }),
      },
      roleName: prefixName+"LambdaAPIInterfaceRole",
      description: "Role for Lambda API Interface",
    });
    lambdaRole.applyRemovalPolicy(RemovalPolicy.DESTROY);

    // Lambda Function that serves as the backend of the QnA Agent Rest API
    const qnaAgentRestApiBackend = new lambda.Function(
      this,
      prefixName+"QnAAgentRestApiBackend",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        code: lambda.Code.fromAsset(
          path.join(basicRestApiLambdaDir, "qna_agent_rest_api"),
        ),
        handler: "qna_agent_rest_api.lambda_handler",
        environment: {
          POWERTOOLS_LOG_LEVEL: "INFO",
          POWERTOOLS_SERVICE_NAME: "QnaAgentApi",
          DEBUG: "false",
          SESSIONS_TABLE: sessionsTable.tableName,
          ...(props.AGENT && { AGENT_ID: props.AGENT.agentId }),
          ...(props.AGENT_ALIAS && { AGENT_ALIAS_ID: props.AGENT_ALIAS }),
        },
        timeout: Duration.seconds(300),
        memorySize: 512,
        layers: [props.LAYER_POWERTOOLS, props.LAYER_BOTO],
        reservedConcurrentExecutions: 5,
        role: lambdaRole,
      },
    );

    const knowledgeBase = props.AGENT_KB;
    if (knowledgeBase) {
      // Add Knolwedge Base id in environment
      qnaAgentRestApiBackend.addEnvironment(
        "KNOWLEDGE_BASE_ID",
        knowledgeBase.knowledgeBaseId,
      );
    }

    // * Amazon API Gateway

    // Basic Rest API with a Custom AWS Lambda Authorizer that calls the QnA Agent
    const qnaAgentRestApi = new apigateway.RestApi(this, prefixName+"QnAAgentRestApi");
    const apiResource = qnaAgentRestApi.root.addResource("qna-agent", {
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
      },
    });
    apiResource.addMethod(
      "POST",
      new apigateway.LambdaIntegration(qnaAgentRestApiBackend),
      {
        authorizationType: apigateway.AuthorizationType.CUSTOM,
        authorizer: new apigateway.TokenAuthorizer(this, "TokenAuthorizer", {
          handler: customAuthorizer,
        }),
      },
    );

    // * Pluggable Constructs can be added below this line

    // Chat Summary feature addition to API interface
    new ChatSummaryWithSessionId(this, prefixName+"ChatSummaryWithSessionId", {
      restApi: qnaAgentRestApi,
      sessionTable: sessionsTable,
      customAuthorizer: customAuthorizer,
      LAYER_BOTO: props.LAYER_BOTO,
      LAYER_POWERTOOLS: props.LAYER_POWERTOOLS,
      PREFIX: prefixName
    });

    // Create Lambda function for Bedrock Agent
    const bedrockAgentLambda = new PythonFunction(this, "BedrockAgentLambda", {
      functionName: `${props.PREFIX}BedrockAgentLambda`,
      entry: path.join(basicRestApiLambdaDir, "qna_agent_rest_api"),
      index: "qna_agent_rest_api.py",
      handler: "lambda_handler",
      runtime: lambda.Runtime.PYTHON_3_11,
      timeout: Duration.seconds(300),
      memorySize: 256,
      layers: [props.LAYER_BOTO, props.LAYER_POWERTOOLS, props.LAYER_PYDANTIC],
      environment: {
        DEBUG: "false",
        SESSIONS_TABLE: sessionsTable.tableName,
        ...(props.AGENT && { AGENT_ID: props.AGENT.agentId }),
        ...(props.AGENT_ALIAS && { AGENT_ALIAS_ID: props.AGENT_ALIAS }),
      },
    });

    // Add permissions to invoke Bedrock Agent
    if (props.AGENT) {
      const bedrockAgentPolicy = new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ["bedrock:InvokeAgent"],
        resources: [
          props.AGENT.agentArn,
          `arn:aws:bedrock:${this.region}:${this.account}:agent-alias/*`,
        ],
      });
      bedrockAgentLambda.addToRolePolicy(bedrockAgentPolicy);
      qnaAgentRestApiBackend.addToRolePolicy(bedrockAgentPolicy);
    }
  }
}
