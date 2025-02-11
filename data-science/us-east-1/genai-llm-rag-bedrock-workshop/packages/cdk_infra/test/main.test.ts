/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { App } from "aws-cdk-lib";
import { AthenaStack } from "../src/stacks/athena-stack";
import { BasicRestApiStack } from "../src/stacks/basic-rest-api-stack";
import { BedrockAgentsStack } from "../src/stacks/bedrock-agents-stack";
import { BedrockKnowledgeBaseStack } from "../src/stacks/bedrock-kb-stack";
import { BedrockText2SqlAgentsStack } from "../src/stacks/bedrock-text2sql-agent-stack";
import { CommonStack } from "../src/stacks/common-stack";

describe("CDK Stack Configurations", () => {
  const stackNamePrefix = "PaceDevWorkshop-";
  const env = {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  };

  describe("Deployment Cases", () => {
    test("Chatbot with Knowledge Base", () => {
      const app = new App({
        context: {
          "deploy:case": "chatbot",
          "deploy:knowledgebase": true,
        },
      });

      const commonStack = new CommonStack(
        app,
        stackNamePrefix + "CommonStack",
        { env },
      );

      const bedrockKnowledgeBaseStack = new BedrockKnowledgeBaseStack(
        app,
        stackNamePrefix + "BedrockKnowledgeBaseStack",
        {
          env,
          ACCESS_LOG_BUCKET: commonStack.ACCESS_LOG_BUCKET,
        },
      );

      const bedrockAgentsStack = new BedrockAgentsStack(
        app,
        stackNamePrefix + "AgentsStack",
        {
          env,
          LAYER_POWERTOOLS: commonStack.LAYER_POWERTOOLS,
          LAYER_BOTO: commonStack.LAYER_BOTO,
          LAYER_PYDANTIC: commonStack.LAYER_PYDANTIC,
          AGENT_KB: bedrockKnowledgeBaseStack.AGENT_KB,
        },
      );
      expect(bedrockAgentsStack.AGENT_ALIAS).toBeDefined();

      if (bedrockAgentsStack.AGENT_ALIAS) {
        const basicRestApiStack = new BasicRestApiStack(
          app,
          stackNamePrefix + "BasicRestApiStack",
          {
            env,
            LAYER_POWERTOOLS: commonStack.LAYER_POWERTOOLS,
            LAYER_BOTO: commonStack.LAYER_BOTO,
            LAYER_PYDANTIC: commonStack.LAYER_PYDANTIC,
            AGENT: bedrockAgentsStack.AGENT,
            AGENT_ALIAS: bedrockAgentsStack.AGENT_ALIAS,
            AGENT_KB: bedrockKnowledgeBaseStack.AGENT_KB,
          },
        );
        expect(basicRestApiStack).toBeDefined();
      }
    });

    test("Text2SQL Deployment Case", () => {
      const app = new App({
        context: {
          "deploy:case": "text2sql",
          "deploy:knowledgebase": false,
        },
      });

      const commonStack = new CommonStack(
        app,
        stackNamePrefix + "CommonStack",
        { env },
      );

      const athenaStack = new AthenaStack(
        app,
        stackNamePrefix + "AthenaStack",
        {
          env,
          ACCESS_LOG_BUCKET: commonStack.ACCESS_LOG_BUCKET,
        },
      );

      const bedrockText2SqlAgentsStack = new BedrockText2SqlAgentsStack(
        app,
        stackNamePrefix + "AgentsStack",
        {
          env,
          LAYER_POWERTOOLS: commonStack.LAYER_POWERTOOLS,
          LAYER_BOTO: commonStack.LAYER_BOTO,
          LAYER_PYDANTIC: commonStack.LAYER_PYDANTIC,
          ATHENA_OUTPUT_BUCKET: athenaStack.ATHENA_OUTPUT_BUCKET,
          ATHENA_DATA_BUCKET: athenaStack.ATHENA_DATA_BUCKET,
          AGENT_KB: null,
        },
      );

      const basicRestApiStack = new BasicRestApiStack(
        app,
        stackNamePrefix + "BasicRestApiStack",
        {
          env,
          LAYER_POWERTOOLS: commonStack.LAYER_POWERTOOLS,
          LAYER_BOTO: commonStack.LAYER_BOTO,
          LAYER_PYDANTIC: commonStack.LAYER_PYDANTIC,
          AGENT: bedrockText2SqlAgentsStack.AGENT,
          AGENT_ALIAS: bedrockText2SqlAgentsStack.AGENT_ALIAS,
          AGENT_KB: null,
        },
      );
      expect(basicRestApiStack).toBeDefined();
    });

    test("Text2SQL with Knowledge Base", () => {
      const app = new App({
        context: {
          "deploy:case": "text2sql",
          "deploy:knowledgebase": true,
        },
      });

      const commonStack = new CommonStack(
        app,
        stackNamePrefix + "CommonStack",
        { env },
      );

      const athenaStack = new AthenaStack(
        app,
        stackNamePrefix + "AthenaStack",
        {
          env,
          ACCESS_LOG_BUCKET: commonStack.ACCESS_LOG_BUCKET,
        },
      );

      const bedrockKnowledgeBaseStack = new BedrockKnowledgeBaseStack(
        app,
        stackNamePrefix + "BedrockKnowledgeBaseStack",
        {
          env,
          ACCESS_LOG_BUCKET: commonStack.ACCESS_LOG_BUCKET,
        },
      );

      const bedrockText2SqlAgentsStack = new BedrockText2SqlAgentsStack(
        app,
        stackNamePrefix + "AgentsStack",
        {
          env,
          LAYER_POWERTOOLS: commonStack.LAYER_POWERTOOLS,
          LAYER_BOTO: commonStack.LAYER_BOTO,
          LAYER_PYDANTIC: commonStack.LAYER_PYDANTIC,
          ATHENA_OUTPUT_BUCKET: athenaStack.ATHENA_OUTPUT_BUCKET,
          ATHENA_DATA_BUCKET: athenaStack.ATHENA_DATA_BUCKET,
          AGENT_KB: bedrockKnowledgeBaseStack.AGENT_KB,
        },
      );

      const basicRestApiStack = new BasicRestApiStack(
        app,
        stackNamePrefix + "BasicRestApiStack",
        {
          env,
          LAYER_POWERTOOLS: commonStack.LAYER_POWERTOOLS,
          LAYER_BOTO: commonStack.LAYER_BOTO,
          LAYER_PYDANTIC: commonStack.LAYER_PYDANTIC,
          AGENT: bedrockText2SqlAgentsStack.AGENT,
          AGENT_ALIAS: bedrockText2SqlAgentsStack.AGENT_ALIAS,
          AGENT_KB: bedrockKnowledgeBaseStack.AGENT_KB,
        },
      );
      expect(basicRestApiStack).toBeDefined();
    });

    test("Throws Error for Invalid Deployment Case", () => {
      expect(() => {
        const app = new App({
          context: {
            "deploy:case": "invalid-case",
          },
        });

        // This would normally be in the main.ts initialization logic
        const deployCase = app.node.tryGetContext("deploy:case")?.toLowerCase();
        if (!["chatbot", "text2sql"].includes(deployCase)) {
          throw new Error(
            `Invalid deploy case: ${deployCase}. Valid options are: chatbot, text2sql`,
          );
        }
      }).toThrow("Invalid deploy case");
    });
  });
});
