/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as path from "path";
import { UserIdentity, UserPoolWithMfa } from "@aws/pdk/identity";
import { PythonLayerVersion } from "@aws-cdk/aws-lambda-python-alpha";
import {
  Stack,
  StackProps,
  RemovalPolicy,
  CfnOutput,
  Duration,
} from "aws-cdk-lib";
import {
  Mfa,
  CfnUserPoolGroup,
  CfnUserPoolUser,
  CfnUserPoolUserToGroupAttachment,
} from "aws-cdk-lib/aws-cognito";
import * as iam from "aws-cdk-lib/aws-iam";
import { Architecture, Runtime } from "aws-cdk-lib/aws-lambda";
import * as s3 from "aws-cdk-lib/aws-s3";
import { NagSuppressions } from "cdk-nag";
import { Construct } from "constructs";

export class CommonStack extends Stack {
  public readonly LAYER_BOTO: PythonLayerVersion;
  public readonly LAYER_POWERTOOLS: PythonLayerVersion;
  public readonly LAYER_PYDANTIC: PythonLayerVersion;
  public readonly USER_IDENTITY: UserIdentity;
  public readonly ACCESS_LOG_BUCKET: s3.Bucket;

  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);
    // * Amazon S3 with Lifecycle policy
    const accessLogsBucket = new s3.Bucket(this, "AccessLogsBucket", {
      enforceSSL: true,
      versioned: true,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      lifecycleRules: [
        {
          id: "TransitionToGlacierAndEventuallyDelete",
          enabled: true,
          transitions: [
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: Duration.days(90),
            },
          ],
          expiration: Duration.days(365),
        },
      ],
    });
    this.ACCESS_LOG_BUCKET = accessLogsBucket;

    NagSuppressions.addResourceSuppressions(accessLogsBucket, [
      {
        id: "AwsSolutions-S1",
        reason:
          "This is the bucket for enabling Access Logging of other Buckets.",
      },
    ]);

    // * AWS Lambda Layers for Python
    let commonLayersDir = "src/backend/common/layers";
    this.LAYER_BOTO = new PythonLayerVersion(this, "Boto3Layer", {
      entry: path.join(commonLayersDir, "boto3_latest"),
      compatibleRuntimes: [Runtime.PYTHON_3_11],
    });

    this.LAYER_POWERTOOLS = new PythonLayerVersion(
      this,
      "LambdaPowertoolsLayer",
      {
        entry: path.join(commonLayersDir, "aws_lambda_powertools_2.43.1"),
        compatibleRuntimes: [Runtime.PYTHON_3_11],
        compatibleArchitectures: [Architecture.X86_64, Architecture.ARM_64],
      },
    );

    this.LAYER_PYDANTIC = new PythonLayerVersion(this, "PydanticV11012Layer", {
      entry: path.join(commonLayersDir, "pydantic_1.10.12"),
      compatibleRuntimes: [Runtime.PYTHON_3_11],
      compatibleArchitectures: [Architecture.X86_64, Architecture.ARM_64],
    });

    // * Amazon Cognito (From PDK's User Identity)
    const userIdentity = new UserIdentity(this, `UserIdentity`, {
      userPool: new UserPoolWithMfa(this, `UserPool`, {
        mfa: Mfa.OFF,
        selfSignUpEnabled: true,
      }),
    });

    this.USER_IDENTITY = userIdentity;

    // Sample Users and Groups
    let usersOutput: string[] = [];
    let COGNITO_USERS_GROUPS_MAPPING: Array<{
      group: string;
      users: Array<string>;
    }> = [
      {
        group: "ADMIN",
        users: ["admin"],
      },
      {
        group: "READ_AND_WRITE",
        users: ["writer"],
      },
      {
        group: "READONLY",
        users: ["reader"],
      },
    ];

    if (COGNITO_USERS_GROUPS_MAPPING.length) {
      COGNITO_USERS_GROUPS_MAPPING.forEach(
        (element: { group: string; users: Array<string> }) => {
          // Create User Group
          let userPoolGroup = new CfnUserPoolGroup(this, `${element.group}`, {
            groupName: element.group,
            userPoolId: userIdentity.userPool.userPoolId,
          });

          // Create Users of Group and attach them to their Group
          element.users.forEach((username: string) => {
            let user = new CfnUserPoolUser(this, `${username}`, {
              userPoolId: userIdentity.userPool.userPoolId,
              username: username,
            });

            let userGroupAttachment = new CfnUserPoolUserToGroupAttachment(
              this,
              `${username}ToGroupAttachment`,
              {
                groupName: element.group,
                username: username,
                userPoolId: userIdentity.userPool.userPoolId,
              },
            );

            // Update output variable
            usersOutput.push(element.group + ":" + username);

            // Explicit dependencies
            userGroupAttachment.node.addDependency(userPoolGroup);
            userGroupAttachment.node.addDependency(user);
          });
        },
      );

      // CloudFormation output
      new CfnOutput(this, "CognitoGroupsUsers", {
        description: "Cognito User Group Names and their Users",
        value: usersOutput.map((item) => item).join(", "),
      });
    }

    // Policy that allows Bedrock calls for Authenticated Users only
    const bedrockPolicyDocument = new iam.PolicyDocument({
      statements: [
        new iam.PolicyStatement({
          resources: ["*"],
          actions: [
            "bedrock:InvokeModel*",
            "bedrock:List*",
            "bedrock:Retrieve*",
            "bedrock:InvokeAgent",
            "bedrock:ListAgents",
            "bedrock:ListAgentAliases",
          ],
          effect: iam.Effect.ALLOW,
        }),
      ],
    });
    // Add the policy document to the authenticated role in the Identity Pool
    userIdentity.identityPool.authenticatedRole.attachInlinePolicy(
      new iam.Policy(this, "bedrock-access-policy", {
        document: bedrockPolicyDocument,
      }),
    );
  }
}
