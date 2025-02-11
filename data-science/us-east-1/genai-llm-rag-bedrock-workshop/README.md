# PACE Generative AI Developer Workshop

## Introduction

This workshop provides a CDK scaffolding for rapid prototyping of AI-powered applications using Amazon Bedrock Knowledge Bases and Agents. 
The full-stack template includes pre-built infrastructure, sample implementations, and customizable components that you can use to quickly build and validate your own AI solutions.

### Purpose

- Accelerate development with production-ready infrastructure templates
- Enable quick proof-of-concept development for custom use cases
- Demonstrate best practices for integrating Amazon Bedrock services

You can use this template as a foundation and modify components, prompts, and integrations to match your specific requirements.

## Prerequisites

### Required AWS Setup
- [ ] AWS Account with administrative access
- [ ] Amazon Bedrock Model access:
   - Claude (Sonnet 3, 3.5) for Bedrock Agent
   - Titan Embeddings v2 for Knowledge Base
   - Nova Lite for Chat Summary (Optional)
- [ ] CDK bootstrapped in your target region (Recommended region: `us-west-2`)
  ```bash
  cdk bootstrap aws://ACCOUNT-NUMBER/REGION
  ```
  - If you use a different region, ensure [the AWS services](packages/cdk_infra/README.md) and [foundation models required for this project](./README.md/#required-aws-setup) are supported in your chosen region.
  - Using a different region will require changing region settings in some subsequent steps. Guidance for these changes will be provided later in the instructions.

### Development Environment

| Tool              | Version  | Installation Guide                                                                                                    | Note                                                                                         |
|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| AWS CLI           | Latest   | [Download](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)                             |                                                                                              |
| AWS CDK           | Latest   | [Github](https://github.com/aws/aws-cdk?tab=readme-ov-file#at-a-glance)                                               |                                                                                              |
| Docker            | -        | [Download](https://www.docker.com/products/docker-desktop/)                                                           | Alternative: [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/) |
| Node.js           | ≥20.18.1 | [Download](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)                                         |                                                                                              |
| PNPM              | 9.15.0   | [Download](https://pnpm.io/)                                                                                          | Package Manager                                                                              |
| Python            | ≥3.12    | [Download](https://www.python.org/downloads/)                                                                         | For OpenAPI schema                                                                           |
| GraphViz          | -        | [Download](https://graphviz.org/download/)                                                                            | For CDK diagrams                                                                             |
| API Testing Tools | -        | Any REST API testing tool such as [Postman](https://www.postman.com/downloads/) or [Bruno](https://www.usebruno.com/) | For API test                                                                                 |


Verify your environment:

```bash
aws --version
cdk --version
docker --version
node --version
pnpm --version
```

## Repository Structure

This is a monorepo managed with [PNPM Workspaces](https://pnpm.io/workspaces), containing multiple related projects in a single repository.

```directory
bedrock-agent-knowledge-base-actions-workshop    
├── document/              # Documentation and reference materials
├── packages/          
│   ├── cdk_infra/         # Backend infrastructure (AWS CDK)
│   └── reactjs_ui/        # Frontend application (React)
└── pnpm-lock.yaml         # Dependencies lock file

```

## Project Components

### Frontend (`reactjs_ui`)
Demonstration-purpose React application showing how to integrate Bedrock Agent with Cognito authentication.
> Note: This is a reference implementation for demonstration only, not intended for production use.

- [View Details](packages/reactjs_ui/README.md)

### Backend (`cdk_infra`)
AWS CDK infrastructure implementing two use cases: Chatbot, Text2SQL

- [View Details](packages/cdk_infra/README.md)

## Getting Started

1. Review the [Backend Implementation](packages/cdk_infra/README.md) and select your use case.
2. Follow the [Deployment Guide](DEPLOYMENT.md) for step-by-step instructions.
3. Customize your solution using the [Customization Guide](docs/CUSTOMIZATION.md).
4. Test your deployment with the [API Testing Guide](docs/API_TESTING.md).
5. When you're done, follow the [Cleanup Guide](docs/CLEANUP.md).

> Note: We recommend keeping the deployed resources for future reference and experimentation. Only proceed with cleanup when you're certain you no longer need these resources.

## Support

If you encounter any issues or have questions, please check our [FAQ](docs/FAQ.md).