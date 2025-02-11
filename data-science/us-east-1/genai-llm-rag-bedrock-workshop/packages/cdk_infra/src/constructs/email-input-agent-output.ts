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
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as eventsources from "aws-cdk-lib/aws-lambda-event-sources";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as ses from "aws-cdk-lib/aws-ses";
import * as sesActions from "aws-cdk-lib/aws-ses-actions";
import { Construct } from "constructs";

export interface EmailInputOutputProcessingProps {
  agentId: string;
  agentAliasId: string;
  agentArn: string;
}

export class EmailInputOutputProcessing extends Construct {
  constructor(
    scope: Construct,
    id: string,
    props: EmailInputOutputProcessingProps,
  ) {
    super(scope, id);

    // * Useful variables
    let emailProcessingLambdaDir = "src/backend/email_processing/lambda";
    let emailProcessingMailParserLambdaLayerDir =
      "src/backend/email_processing/layers/mailparser";

    // Create S3 Bucket that stores emails
    const emailBucket = new s3.Bucket(this, "ReceivingEmailsBucket", {
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      enforceSSL: true,
      versioned: true,
    });

    // Create Lambda Layer for mail-parser
    const mailParserLayer = new PythonLayerVersion(
      this,
      "PythonMailParserLayerLatest",
      {
        entry: path.join(emailProcessingMailParserLambdaLayerDir),
        compatibleRuntimes: [lambda.Runtime.PYTHON_3_11],
      },
    );

    // Create the Lambda function
    const emailProcessingFunction = new PythonFunction(
      this,
      "EmailProcessingFunction",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        entry: path.join(emailProcessingLambdaDir),
        index: "email_processing.py",
        handler: "lambda_handler",
        timeout: Duration.seconds(120),
        memorySize: 512,
        reservedConcurrentExecutions: 5,
        layers: [mailParserLayer],
        environment: {
          DEBUG: "false",
          AGENT_ARN: props.agentArn,
          AGENT_ALIAS_ID: props.agentAliasId,
          AGENT_ID: props.agentId,
        },
      },
    );

    // Allow Lambda to read/write from bucket
    emailBucket.grantReadWrite(emailProcessingFunction);

    // Add S3 bucket object insertion as the trigger event for the Lambda function
    emailProcessingFunction.addEventSource(
      new eventsources.S3EventSource(emailBucket, {
        events: [s3.EventType.OBJECT_CREATED],
      }),
    );

    // Create the SES email receiving rule
    const receivingEmailSesRule = new ses.ReceiptRule(
      this,
      "ReceivingEmailSesRule",
      {
        ruleSet: new ses.ReceiptRuleSet(this, "ReceivingEmailRuleSet", {
          receiptRuleSetName: "ReceivingEmailRuleSet",
        }),
        recipients: ["*@yourdomain.com"], // Replace with your email address
        actions: [
          new sesActions.Lambda({
            function: emailProcessingFunction,
            invocationType: sesActions.LambdaInvocationType.EVENT,
          }),
        ],
        enabled: false,
      },
    );

    // Grant the Lambda function permissions to send emails using SES
    emailProcessingFunction.addPermission("AllowSESInvocation", {
      principal: new iam.ServicePrincipal("ses.amazonaws.com"),
    });

    // Grant the Lambda function permissions to call the Amazon Bedrock Agent
    emailProcessingFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ["bedrock:InvokeAgent"],
        resources: [
          props.agentArn,
          `arn:aws:bedrock:*:*:agent-alias/${props.agentId}/*`,
        ],
      }),
    );

    emailProcessingFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ["ses:SendEmail"],
        resources: ["arn:aws:ses:*:*:identity/*"],
      }),
    );
  }
}
