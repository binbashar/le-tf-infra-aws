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
import { AgentActionGroup } from "@cdklabs/generative-ai-cdk-constructs/lib/cdk-lib/bedrock";
import { Stack, StackProps, Duration } from "aws-cdk-lib";
import { ServicePrincipal } from "aws-cdk-lib/aws-iam";
import { Runtime } from "aws-cdk-lib/aws-lambda";
import * as cdk from "aws-cdk-lib/core";
import { Construct } from "constructs";
// * Commented imports for pluggable constructs
// import { EmailInputOutputProcessing } from '../constructs/email-input-agent-output';

interface BedrockAgentsStackProps extends StackProps {
  AGENT_KB: bedrock.KnowledgeBase | null;
  LAYER_BOTO: PythonLayerVersion;
  LAYER_POWERTOOLS: PythonLayerVersion;
  LAYER_PYDANTIC: PythonLayerVersion;
}

export class BedrockAgentsStack extends Stack {
  public readonly AGENT: bedrock.Agent;
  public readonly AGENT_ALIAS: string | undefined;

  constructor(scope: Construct, id: string, props: BedrockAgentsStackProps) {
    super(scope, id, props);

    // * Export system prompt - update prompt files from local
    const instruction = readFileSync(
      path.join(__dirname, "../../prompt/instruction/chatbot", "instruction.txt"), // chatbot
      "utf8",
    );

    // * Amazon Bedrock Agent
    const qnaActionsAgent = new bedrock.Agent(this, "QnAActionsAgent", {
      name: (cdk.Stack.of(this) + "-" + "QnAActionsAgent").replace("/", "-"),
      foundationModel:
        bedrock.BedrockFoundationModel.ANTHROPIC_CLAUDE_SONNET_V1_0,
      shouldPrepareAgent: true,
      enableUserInput: true,
      instruction:
        "You are a helpful and friendly customer service agent for " +
        this.node.tryGetContext("custom:companyName") +
        " named " +
        this.node.tryGetContext("custom:agentName") +
        ". " +
        instruction,
      description:
        "Agent used for executing Actions, and also for Question Answering from a Knowledge Base",
      aliasName: "latest",
    });

    this.AGENT = qnaActionsAgent;
    this.AGENT_ALIAS = qnaActionsAgent.aliasId;

    // Agent Actions
    let agentsLambdaDir = "src/backend/agents/lambda";
    const agentAccountActions = new PythonFunction(
      this,
      "AgentAccountActions",
      {
        runtime: Runtime.PYTHON_3_11,
        entry: path.join(agentsLambdaDir, "account_actions"),
        index: "account_actions.py",
        handler: "lambda_handler",
        timeout: Duration.seconds(300),
        memorySize: 2048,
        reservedConcurrentExecutions: 5,
        layers: [
          props.LAYER_BOTO,
          props.LAYER_POWERTOOLS,
          props.LAYER_PYDANTIC,
        ],
        environment: {
          DEBUG: "false",
        },
      },
    );
    agentAccountActions.addPermission("AmazonBedrockPermission", {
      principal: new ServicePrincipal("bedrock.amazonaws.com"),
      sourceArn: qnaActionsAgent.agentArn,
    });

    // Agent Action Group
    qnaActionsAgent.addActionGroup(
      new AgentActionGroup(this, "QnAActionsAgentAG", {
        actionGroupName: "agent-account-actions",
        description:
          "Use these functions to take actions on authenticated user's accounts",
        actionGroupExecutor: {
          lambda: agentAccountActions,
        },
        actionGroupState: "ENABLED",
        apiSchema: bedrock.ApiSchema.fromAsset(
          path.join(agentsLambdaDir, "account_actions", "openapi.json"),
        ),
      }),
    );

    // Create CloudWatch Dashboard for Bedrock
    const bddashboard = new BedrockCwDashboard(
      this,
      "BedrockDashboardConstruct",
      {
        dashboardName: "PACEGenAIWorkshopBedrockDashboard",
      },
    );

    // provides monitoring of all models
    bddashboard.addAllModelsMonitoring();

    // provides monitoring for a specific model with on-demand pricing calculation
    // pricing details are available here: https://aws.amazon.com/bedrock/pricing/
    bddashboard.addModelMonitoring(
      "Claude Sonnet 3",
      // Claude Sonnet 3 ARN (us-west-2) - Update region in ARN if necessary
      "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
      {
        inputTokenPrice: 0.003, // On-demand Price per 1K input tokens
        outputTokenPrice: 0.015, // Price per 1K output tokens
      },
    );

    const knowledgeBase = props.AGENT_KB;
    if (knowledgeBase) {
      // Add Knowledge Base to the agent
      qnaActionsAgent.addKnowledgeBase(knowledgeBase);

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

    // * Pluggable Constructs can be added below this line

    // Example: Add an Email Input/Output Channel for the QnA Agent. Uncomment and update imports to use.
    // const emailProcessing = new EmailInputOutputProcessing(this, 'EmailProcessingConstruct', {
    //     agentId: this.QNA_ACTIONS_AGENT.agentId,
    //     agentAliasId: this.QNA_ACTIONS_AGENT.aliasId ?? "",
    //     agentArn: this.QNA_ACTIONS_AGENT.agentArn
    // });
  }
}
