# Infrastructure Setup for Data Science GenAI LLM RAG Demo

This guide provides instructions for setting up the infrastructure required for the Data Science GenAI LLM RAG Demo.

## Steps to Set Up the Infrastructure

1. **Log in to the AWS Management Console**  
   Open your web browser and log in to your AWS account.

2. **Navigate to AWS Secrets Manager**  
   In the AWS Management Console, search for and select **Secrets Manager**.

3. **Find the Secret**  
   In the Secrets Manager dashboard, locate the secret that starts with `/data-science/genai-llm-rag-demo`.

4. **Edit the Secret**  
   - Click on the secret to view its details.
   - Click on the **Edit secret** button.

5. **Add the Password Key**  
   - In the **Key/Value pairs** section, add a new key with the following details:
     - **Key**: `PWD_DEMO`
     - **Value**: `<your_specific_password>` (replace this with the specific password you will use for the demo)

6. **Save Changes**  
   - After adding the key and value, scroll down and click on the **Next** button.
   - Review your changes and click on **Save**.

## Building the Docker Image

In order for the demo to work, you need to create the Docker image following the steps outlined in the README located in the GenAI repository. 