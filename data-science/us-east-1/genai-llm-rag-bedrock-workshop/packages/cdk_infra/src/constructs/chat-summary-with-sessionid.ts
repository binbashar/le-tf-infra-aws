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
import { Duration, RemovalPolicy } from "aws-cdk-lib";
import * as apigateway from "aws-cdk-lib/aws-apigateway";
import { Table } from "aws-cdk-lib/aws-dynamodb";
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";

export interface ChatSummaryWithSessionIdProps {
  restApi: apigateway.RestApi;
  sessionTable: Table;
  customAuthorizer: PythonFunction;
  LAYER_BOTO: PythonLayerVersion;
  LAYER_POWERTOOLS: PythonLayerVersion;
  PREFIX: string;
}

export class ChatSummaryWithSessionId extends Construct {
  constructor(
    scope: Construct,
    id: string,
    _props: ChatSummaryWithSessionIdProps,
  ) {
    super(scope, id);

    // * AWS Lambda
    let chatSummaryLambdaDir = "src/backend/chat_summary/lambda";

    // Lambda function role for log access, dynamodb read/write permissions, and bedrock invocation permissions.
    const lambdaRole = new iam.Role(this, _props.PREFIX+"CustomAuthorizerRole", {
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
              resources: [_props.sessionTable.tableArn],
            }),
          ],
        }),
        bedrockModelAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ["bedrock:InvokeModel"],
              resources: [
                `arn:aws:bedrock:us-east-1:${process.env.CDK_DEFAULT_ACCOUNT}:inference-profile/us.amazon.nova-lite-v1:0`,
                `arn:aws:bedrock:us-east-2:${process.env.CDK_DEFAULT_ACCOUNT}:inference-profile/us.amazon.nova-lite-v1:0`,
                `arn:aws:bedrock:us-west-2:${process.env.CDK_DEFAULT_ACCOUNT}:inference-profile/us.amazon.nova-lite-v1:0`,
                "arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-lite-v1:0",
                "arn:aws:bedrock:us-east-2::foundation-model/amazon.nova-lite-v1:0",
                "arn:aws:bedrock:us-west-2::foundation-model/amazon.nova-lite-v1:0",
              ],
            }),
          ],
        }),
      },
      roleName: _props.PREFIX+"LambdaChatSummaryRole",
      description: "Role for Chat Summarization Lambda",
    });
    lambdaRole.applyRemovalPolicy(RemovalPolicy.DESTROY);

    // AWS Lambda function
    const chatSummaryWithSessionIdBackend = new lambda.Function(
      this,
      _props.PREFIX+"ChatSummaryWithSessionIdLambda",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        code: lambda.Code.fromAsset(path.join(chatSummaryLambdaDir)),
        handler: "chat_summary.lambda_handler",
        environment: {
          SESSION_TABLE: _props.sessionTable.tableName,
        },
        timeout: Duration.seconds(300),
        memorySize: 256,
        role: lambdaRole,
        layers: [_props.LAYER_BOTO, _props.LAYER_POWERTOOLS],
      },
    );

    // * Amazon API Gateway
    const apiResource = _props.restApi.root.addResource("chat-summary", {
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
      },
    });
    apiResource.addMethod(
      "POST",
      new apigateway.LambdaIntegration(chatSummaryWithSessionIdBackend),
      {
        authorizationType: apigateway.AuthorizationType.CUSTOM,
        authorizer: new apigateway.TokenAuthorizer(this, "TokenAuthorizer", {
          handler: _props.customAuthorizer,
        }),
      },
    );
  }
}
