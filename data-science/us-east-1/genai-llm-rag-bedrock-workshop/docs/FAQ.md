# Frequently Asked Questions (FAQ)

This document addresses common questions and provides troubleshooting tips for the PACE Generative AI Developer Workshop.

## Table of Contents

1. [Bedrock Knowledge Bases](#bedrock-knowledge-bases)
2. [Bedrock Agents](#bedrock-agents)
3. [Bedrock - Other Topics](#bedrock---other-topics)
4. [Workshop-Specific Questions](#workshop-specific-questions)

## Bedrock Knowledge Bases

### Q: Can I configure role-based access for Bedrock Knowledge Bases?
A: Yes, our CDK includes sample context passing to the Bedrock agent when invoking. For more details, see [this AWS blog post](https://aws.amazon.com/es/blogs/machine-learning/access-control-for-vector-stores-using-metadata-filtering-with-knowledge-bases-for-amazon-bedrock/).

### Q: Can I use nested JSON for metadata in Knowledge Bases?
A: No, KB metadata cannot be nested JSON. It will result in an error.

## Bedrock Agents

### Q: How can I make certain parameters optional in Bedrock Agent actions?
A: Use Python's `Optional` type and provide a default value. Example:

```python
from typing import Annotated, Optional

def password_change(email: str, phone: Optional[str] = None):
    # Function logic
```

### Q: How can I improve Bedrock Agent response times?
A: Consider the following options:
1. If the response processing is slow in Lambda, consider increasing Lambda size.
2. Tell the agent to limit the response length using prompts.
3. To improve Knowledge base response, consider KB metadata filtering.
4. Consider Provisioned Throughput:
    - Bedrock agent can consume provisioned throughput together
    - Most models support no-commitment purchase
5. Consider limiting number of actions for a single agent (Soft limit is 11), and having multiple agents if required (long term).
6. Implement a caching layer (long term solution).

### Q: How do I handle "max iterations exceeded" errors?
A: This is a hard limit set by Bedrock. To address this:
- Ensure your requests aren't stuck in loops or repeatedly asking the same questions.
- Optimize your action invocations.
- Use session attributes to avoid redundant calls.
- Consider making parameters optional in your actions.
- Limit the number of APIs available to a single agent.

* [Reference](https://repost.aws/questions/QUazRyCtdbSvqFV2fWJMzu3A/aws-bedrock-agent-failurereason-max-iterations-exceeded)

### Q: How can I control which actions an agent calls?
A: Customize the orchestration prompt template to guide the model on action selection. In the orchestration step, modify the prompt template to provide clear examples, rules, or constraints that steer the model away from invoking multiple redundant actions.

### Q: Are there best practices for designing agent actions?
A: Yes, key points include:
- Limit to 11 APIs per agent (soft limit)
- Follow general best practices for API design
- Implement thorough input validation
- Create focused agents for specific tasks
- Ensure clear objectives and a focused set of available actions

### Q: Should an agent use multiple action groups?
A: Agents work best with a small number of actions. The soft limit is 11 actions and knowledge bases per agent. If you need more functionality, consider creating separate agents for different tasks.
* [Reference](https://docs.aws.amazon.com/bedrock/latest/userguide/quotas.html)

## Bedrock - others

### Q: What are the best practices for prompt engineering?

A: Prompt engineering is a crucial aspect of developing effective chatbots and language models. It involves crafting the prompts or instructions given to the model in a way that elicits the desired response. Here are some best practices for prompt engineering:

1. Clarity and Specificity: Ensure that your prompts are clear, concise, and specific. Ambiguous or vague prompts can lead to confusing or irrelevant responses.
2. Context and Examples: Provide relevant context and examples to help the model better understand the task or query. This can include background information, sample inputs, and expected outputs. Additionally, you can leverage techniques like zero-shot learning (providing only the task description), one-shot learning (providing a single example), or few-shot learning (providing a few examples) to guide the model's understanding.
3. Iterative Refinement: Prompt engineering is an iterative process. Start with a basic prompt and refine it based on the model's responses and performance. Continuously evaluate and adjust the prompts to improve the quality of the outputs.

*References:*

* [AWS re:Invent 2023 - Prompt engineering best practices for LLMs on Amazon Bedrock (AIM377)](https://youtu.be/jlqgGkh1wzY?feature=shared)
* [[Blog post] Prompt engineering techniques and best practices: Learn by doing with Anthropic’s Claude 3 on Amazon Bedrock](https://aws.amazon.com/blogs/machine-learning/prompt-engineering-techniques-and-best-practices-learn-by-doing-with-anthropics-claude-3-on-amazon-bedrock/)
* [Anthropic prompt engineering guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview)

## Workshop

### Q: When running `pnpm cdk_infra:deploy`, I get the error: "ERR_PNPM_RECURSIVE_EXEC_FIRST_FAIL Command "cdk_infra:deploy" not found". Is there something I am missing?

A: This error typically occurs when you're not in the correct directory when running the command. To resolve this issue:

1. Ensure you are in the root directory of the project when running pnpm commands.

2. The correct directory is where the main `package.json` file is located, which contains the script definitions for the project.

3. If you're unsure about the project structure, verify your current directory:
   - On Unix-like systems (Linux, macOS), use the `pwd` command.
   - On Windows, use the `cd` command without any arguments or `echo %cd%`.
4. Once you've confirmed you're in the root directory, try running the command again.
   
### Q: Why am I getting an "ERR_PNPM_RECURSIVE_RUN_FIRST_FAIL" error when running pnpm commands, and how can I fix it?

A: The "ERR_PNPM_RECURSIVE_RUN_FIRST_FAIL" error typically occurs when Node.js runs out of memory while executing a pnpm command, especially in large projects or when running resource-intensive tasks.

To resolve this issue, you can increase the memory allocation for Node.js using the `NODE_OPTIONS` environment variable. Here's how to do it:

1. Prefix your pnpm command with `NODE_OPTIONS=--max_old_space_size=8192`
2. Run your command as usual

For example:

```bash
NODE_OPTIONS=--max_old_space_size=8192 pnpm yourcommand
```

This sets the maximum old space size to 8GB (8192MB), which should be sufficient for most tasks. 
If you're still encountering issues, you can try increasing this value further, e.g., to 16384 for 16GB.

### Q: How can I manage dependencies using pnpm?

A: To add or update dependencies for an application or development tool managed by this repository, modify its respective `package.json` file.

* `pnpm install` - Install all dependencies across all packages and development tools
* `pnpm update` - Update all dependencies across all packages, adhering to ranges specified in package.json
* `pnpm build` - Builds all applications within packages, first it updates all the license headers, and installs all the python dev dependencies in a virtual environment, then for `cdk_infra` it updates all OpenAPI schemas and synthesizes the application, and for `reactjs_ui` it builds the application
* `pnpm deploy` - Deploys the `cdk_infra` application to the AWS account that was previously CDK bootstrapped in a specific AWS region.

### Q: How much does the workshop cost? Specifically for Bedrock?

A: The workshop extensively utilizes AWS serverless services, such as Amazon DynamoDB, AWS Lambda, and API Gateway, which are eligible for the AWS Free Tier. However, not all services provisioned by the workshop are eligible for the Free Tier, such as Amazon OpenSearch Serverless or Amazon Bedrock. The cost of Amazon OpenSearch Serverless may vary depending on the used OpenSearch Compute Units (OCUs) and the managed storage volume, but you can expect a minimum cost of $700-800 per month. The costs are based on a pay-as-you-go model, and you can find [the pricing details for each service on the AWS official website.](https://aws.amazon.com/pricing)

The workshop includes a sample CloudWatch Dashboard that demonstrates the number of input and output tokens and provides an estimated billing amount. Please note that this token-usage based estimate is applicable only for the specific models used in the workshop and does not include storage costs or others.

### Q: How does API Gateway authorize the request in the workshop?

A: The API Gateway in the workshop uses AWS Lambda Authorizer as an example for controlling and managing access to the API. Specifically in this workshop, the API gateway is designed to require an authentication header in the request. (Authorization - allowed)

API Gateway supports multiple mechanisms for controlling and managing access to your API, and you can find other methods in the documentation: [Control and manage access to REST APIs in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-control-access-to-api.html).

For more information on Lambda authorizers, you can refer to the documentation on [Use API Gateway Lambda authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html).

### Q: What is the Chat Summary Construct for? What are the differences between Chat Summary and Bedrock Memory Retention?

A: The Chat Summary Construct is designed to provide a summary of the conversation to a human agent or for analysis purposes. When enabled, it adds a `/chat-summary` path to your API Gateway. By sending a POST request with the session ID to this path, the backend Lambda function will send a summary request to Amazon Bedrock, which will use the  Anthropic’s Claude 3 Haiku model. The Haiku model will generate a concise summary of the conversation, which can be useful in scenarios where you want to engage a human live agent or review frequently asked questions.

The common purpose of the both Chat Summary and Bedrock Memory Retention is to remember previous conversations, while there are some differences between them:

* Memory Retention is a native preview feature supported in Bedrock Agent. It is to provide contextual conversations to the Bedrock Agent. Meanwhile, Chat Summary construct reads chat history from DynamoDB and explicitely sends summarization request to the Bedrock Haiku model. You can flexibly modify the instruction, such as output format.
* Memory Retention stores session summaries for a configurable duration (1-30 days). Chat Summary is a one-time summary request and you will have the summary in the response of API request. You can design to store the data in an external database (e.g. DDB), if you’d like to keep them more than 30 days.

**Reference:** [Use memory to retain conversational context across multiple sessions](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-memory.html) (Note: The Memory for Agents feature is in preview release for Amazon Bedrock and is subject to change.) 

### Q: I don't see model monitoring metrics in the CloudWatch dashboard. What could be the reason?

A: If you're not seeing model monitoring metrics in your CloudWatch dashboard, it's likely due to using an incorrect model ID. Here are some steps to troubleshoot:

1. Ensure you're using the correct model ID for your region. By default, the workshop uses the `us-west-2` region.

2. Check the model ARN in your code. For example, the default Claude 3 Sonnet model ARN for `us-west-2` is:

   ```typescript
   "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"
   ```
   If you're deploying to a different region, make sure to update the region in the ARN accordingly.

   Locate the file where the model ID is defined:

   - For the Chatbot: packages/cdk_infra/src/stacks/bedrock-agent-stacks.ts
   - For Text2SQL: packages/cdk_infra/src/stacks/bedrock-text2sql-agent-stacks.ts

   Update the model ID correctly based on your deployment case.

   After making any changes, redeploy your infrastructure to ensure the updates take effect.
