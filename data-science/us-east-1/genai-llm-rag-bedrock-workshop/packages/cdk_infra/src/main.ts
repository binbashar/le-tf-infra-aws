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
import { ChatBotStack } from "./stacks/chatbot/chatbot";
import { DocumentProcessingStack } from "./stacks/documentprocessing/documentprocessing";

// Define deployment case enum
enum DeployCase {
  CHATBOT = "chatbot",
  TEXT2SQL = "text2sql",
  DOCUMENTPROCESSING = "documentprocessing",
  ALL = "all",
}

// Function to get the deployment case
function getDeployCase(app: App): DeployCase {
  const deploymentCase = app.node.tryGetContext("deploy:case");
  if (deploymentCase === undefined) {
    return DeployCase.ALL;
  }

  // Check if given deployment case is valid
  if (
    deploymentCase === DeployCase.CHATBOT ||
    deploymentCase === DeployCase.DOCUMENTPROCESSING ||
    deploymentCase === DeployCase.TEXT2SQL ||
    deploymentCase === DeployCase.ALL
  ) {
    return deploymentCase;
  }
  throw new Error(
    `Invalid deployment case: ${deploymentCase}. Must be one of ${Object.values(
      DeployCase,
    ).join(", ")}`,
  );
}

/* eslint-disable @typescript-eslint/no-floating-promises */
(async () => {
  const app = PDKNag.app({
    nagPacks: [new AwsPrototypingChecks()],
  });
  // * Setting stack name prefix
  const stackNamePrefix = "BinbashWorkshop-";

  // Setting Common Environment
  const env = {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  };

  // Get the deployment case
  const deployCase = getDeployCase(app);
  const bb_deployment_version = "1.0.0"
  const deployment_name = "bb_workshop_prime"
  // * Create commonStack
  const commonStack = new CommonStack(app, stackNamePrefix + "CommonStack", {
    env: env,
    description:"BINBASH WORKSHOP (uksb-arjmsrldpz)(tag:" + deployCase + ", " + bb_deployment_version + ", " + deployment_name + ")",
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

    case DeployCase.DOCUMENTPROCESSING:
      // const documentProcessingStack = new DocumentProcessingStack(
      //   app,
      //   stackNamePrefix + "DocumentProcessingStack",
      //   {
      //     env: env,
      //     stackNamePrefix: deployCase,
      //     commonStack: commonStack,
      //     bedrockKnowledgeBaseStack: bedrockKnowledgeBaseStack
      //   },
      // );
      console.warn("Deployment of 'documentprocessing' case is disabled in main.ts.");
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

      // Commenting out the instantiation of DocumentProcessingStack for the 'all' case
      // const documentProcessingStackAll = new DocumentProcessingStack(
      //   app,
      //   stackNamePrefix + "DocumentProcessingStack",
      //   {
      //     env: env,
      //     stackNamePrefix: "documentprocessing",
      //     commonStack: commonStack,
      //     bedrockKnowledgeBaseStack: bedrockKnowledgeBaseStack
      //   },
      // ); 
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
  Tags.of(app).add("creator", "Binbash");
  Tags.of(app).add("project", "GenAI Innovation Lab Workshop");
  app.synth();
  await graph.report();
})();
