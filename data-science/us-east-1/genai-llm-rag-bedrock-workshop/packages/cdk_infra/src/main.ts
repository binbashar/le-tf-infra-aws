/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { CdkGraph, FilterPreset, Filters } from "@aws/pdk/cdk-graph";
import { CdkGraphDiagramPlugin } from "@aws/pdk/cdk-graph-plugin-diagram";
import { CdkGraphThreatComposerPlugin } from "@aws/pdk/cdk-graph-plugin-threat-composer";
import { AwsPrototypingChecks, PDKNag } from "@aws/pdk/pdk-nag";
import { App, Tags } from "aws-cdk-lib";
import { NagSuppressions } from "cdk-nag";
import { AthenaStack } from "./stacks/text2sql/athena-stack";
import { BasicRestApiStack } from "./stacks/basic-rest-api-stack";
import { BedrockAgentsStack } from "./stacks/chatbot/bedrock-agents-stack";
import { BedrockKnowledgeBaseStack } from "./stacks/bedrock-kb-stack";
import { BedrockText2SqlAgentsStack } from "./stacks/text2sql/bedrock-text2sql-agent-stack";
import { CommonStack } from "./stacks/common-stack";
import { Text2SQLStack } from "./stacks/text2sql/text2sql";
import { ChatBotStack } from "./stacks/chatbot/chatbot"

// Define deployment case enum
enum DeployCase {
  CHATBOT = "chatbot",
  TEXT2SQL = "text2sql",
  ALL = "all",
}

// Function to get the deployment case
function getDeployCase(app: App): DeployCase {
  const deployCase = app.node.tryGetContext("deploy:case")?.toLowerCase();

  // Return CHATBOT as default if no input or explicitly set to 'chatbot'
  if (!deployCase || deployCase === DeployCase.CHATBOT) {
    return DeployCase.CHATBOT;
  }

  // Check for TEXT2SQL case
  if (deployCase === DeployCase.TEXT2SQL) {
    return DeployCase.TEXT2SQL;
  }

  // Check for ALL case
  if (deployCase === DeployCase.ALL) {
    return DeployCase.ALL;
  }

  // Throw error for invalid input
  throw new Error(
    `Invalid deploy case: ${deployCase}. Valid options are: ${Object.values(DeployCase).join(", ")}`,
  );
}

/* eslint-disable @typescript-eslint/no-floating-promises */
(async () => {
  const app = PDKNag.app({
    nagPacks: [new AwsPrototypingChecks()],
  });
  // * Setting stack name prefix
  const stackNamePrefix = "PaceDevWorkshop-";

  // Setting Common Environment
  const env = {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  };

  // Get the deployment case
  const deployCase = getDeployCase(app);
  const pace_deployment_version = "1.1.0"
  const deployment_name = "pace_developer_workshop_prime"
  // * Create commonStack
  const commonStack = new CommonStack(app, stackNamePrefix + "CommonStack", {
    env: env,
    description:"PACE DEVELOPER WORKSHOP (uksb-arjmsrldpz)(tag:" + deployCase + ", " + pace_deployment_version + ", " + deployment_name + ")",
    stackName: stackNamePrefix + "CommonStack",
  });


  // Declare bedrockKnowledgeBaseStack outside the switch statement
  let bedrockKnowledgeBaseStack: BedrockKnowledgeBaseStack | undefined;

  // Decide to deploy Amazon Bedrock Knowledge Base
  const deployKnowledgeBase = app.node.tryGetContext("deploy:knowledgebase");
  if (deployKnowledgeBase) {
    bedrockKnowledgeBaseStack = new BedrockKnowledgeBaseStack(
      app,
      stackNamePrefix + "BedrockKnowledgeBaseStack",
      {
        env: env,
        ACCESS_LOG_BUCKET: commonStack.ACCESS_LOG_BUCKET,
      },
    );
    bedrockKnowledgeBaseStack.addDependency(commonStack);
  }

  // Create stacks based on deployment case
  switch (deployCase) {
    case DeployCase.TEXT2SQL:
      const text2sqlAgentsStack = new Text2SQLStack(
        app,
        stackNamePrefix + "Text2SQLAgentsStack",
        {
          env: env,
          stackNamePrefix: deployCase,
          commonStack: commonStack,
          bedrockKnowledgeBaseStack: bedrockKnowledgeBaseStack
        },
      );
      break;

    case DeployCase.CHATBOT:
     const chatbotStackAll = new ChatBotStack(
        app,
        stackNamePrefix + "ChatbotStack",
        {
          env: env,
          stackNamePrefix: deployCase,
          commonStack: commonStack,
          bedrockKnowledgeBaseStack: bedrockKnowledgeBaseStack
        },
      );
      break;
    case DeployCase.ALL:
      const text2sqlAgentsStackAll = new Text2SQLStack(
        app,
        stackNamePrefix +"Text2SQLAgentsStack",
        {
          env: env,
          stackNamePrefix: "text2sql",
          commonStack: commonStack,
          bedrockKnowledgeBaseStack: bedrockKnowledgeBaseStack
        },
      );

      const chatbotStack = new ChatBotStack(
        app,
        stackNamePrefix +"ChatbotStack",
        {
          env: env,
          stackNamePrefix: "chatbot",
          commonStack: commonStack,
          bedrockKnowledgeBaseStack: bedrockKnowledgeBaseStack
        },
      );
    break;

    default:
      throw new Error("Invalid deployment case");
  }

  // * Architecture Diagram
  const graph = new CdkGraph(app, {
    plugins: [
      new CdkGraphDiagramPlugin({
        defaults: {
          filterPlan: {
            preset: FilterPreset.COMPACT,
            filters: [{ store: Filters.pruneCustomResources() }],
          },
        },
      }),
      new CdkGraphThreatComposerPlugin(),
    ],
  });

  // * Custom Tags
  Tags.of(app).add("creator", "AWS PACE");
  Tags.of(app).add("project", "Generative AI Developer Workshop");
  app.synth();
  await graph.report();
})();
