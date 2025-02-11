# Frontend Implementation

- Reference implementation showing how to integrate with the backend services. 
- This demonstration UI provides examples of authentication flow, API integration, and basic user interactions.
- Note that this is intended for demonstration purposes only and should be customized for production use.

## Introduction

This ReactJS UI application serves as the frontend for the `packages/cdk_infra` application. 
It provides a user-friendly interface for interacting with Amazon Bedrock Agents, Knowledge Bases, and Large Language Models.

## Features

The application includes the following key features:

- User authentication using Amazon Cognito
- Amazon Bedrock Multimodal Chatbot with support for using System Prompts.
- System Prompts Management (leveraging browser's [local storage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage))
- Amazon Bedrock Agents Chatbot

## Repository Structure

The repository is organized as follows:

```directory
packages/                        
   └── reactjs_ui/               
         ├── public/                          # Static assets         
         ├── src/                             # Source code of UI project
         │   ├── assets/                      # Reusable static assets across components
         │   ├── components/                  # Reusable React components
         │   ├── localData/                   # Manage local storage state
         │   ├── styles/                      # CSS and styling files
         │   ├── utils/                       # Utility functions and helpers
         │   ├── views/                       # Page components
         │   └── aws-exports.js               # Configuration to point to AWS 
         └── package.json                     # Libraries and Dependencies of the project
```

## Key Components

![UI_sample](/assets/images/UI.png)


### Amazon Bedrock LLMs
- **Multimodal Chatbot**: Allows model selection and interaction using stored prompts.
- **System Prompts**: Manage and create custom prompts stored in the browser.

### Amazon Bedrock Agents
- **Agent Chatbot**: Test your agent by selecting agent ID/alias and starting a conversation.

