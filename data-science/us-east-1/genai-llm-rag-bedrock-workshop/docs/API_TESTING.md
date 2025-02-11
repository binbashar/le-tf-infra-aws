# Testing Sample Rest API

## Getting Started

1. Open your API testing tool. (e.g. Postman, Insomnia, Bruno)
2. Go to [API Gateway](https://console.aws.amazon.com/apigateway).
3. You can get the API URL from API Gateway, use the PROD stage URL.

- **URL: {apiurl}/qna-agent**

```json
    {
        "sessionId": "",
        "message" : "Hello",
        "metadata": {} 
    }
```

### Chat summary (Optional)

You can test chat summary construct using the same API Url.

- **URL: {apiurl}/chat-summary**

```json
    {
        "sessionId": "{sessionId}" 
    }
```

### Update Agent Alias

When testing a new version of your customized agent, you need to update the agent alias. This is because:

- Each agent version represents a specific configuration, including:
    - Customized agent instructions
    - Modified orchestration prompts
    - For more information on customizing your prompt, see the [Customize Prompt](CUSTOMIZATION.md#customize-prompts).
- The alias acts as a pointer to a specific agent version, allowing you to switch between different configurations easily.

Follow these steps to update the alias:

1. Open the [Amazon Bedrock Console](https://console.aws.amazon.com/bedrock)
2. Select your agent and create a new version if you've made changes
3. Copy the new alias ID of the new version

Then, update the Lambda function to use the new alias:

1. Go to the [AWS Lambda Console](https://console.aws.amazon.com/lambda)
2. Select the API Backend Lambda function (TODO: provide the exact name)
3. Navigate to the Configuration tab
4. Select "Environment variables"
5. Update the `AGENT_ALIAS_ID` variable with the new alias ID
6. Save the changes

By updating the alias, you can test your new agent configuration without changing your application code.
This allows for easy switching between different versions of your agent during development and testing.
For more information on customizing your agent, see the [Customization Guide](CUSTOMIZATION.md#customize-prompts).

### Metadata Filtering for Knowledge Base

> Note: This section is **only applicable** if you set `"deploy:knowledgebase": true` in your configuration.

Metadata filtering allows you to refine the knowledge base search results based on specific attributes. 
This feature is particularly useful when you have a large knowledge base and want to narrow down the information retrieved by the agent.

#### Setting Up Metadata

1. Prepare your metadata file:
    - Create a JSON file with the same name as your source file, adding the `.metadata.json` suffix.
    - Example: For `bedrock.pdf`, create `bedrock.pdf.metadata.json`.

2. Format your metadata JSON file:

    ```json
    {
        "metadataAttributes": {
            "service": "bedrock",
            "year": 2023
        }
    }
    ```

3. Upload both the source file and its metadata file to your S3 bucket.

4. Synchronize your knowledge base in the Amazon Bedrock console.

> Tip: You can find sample documents and metadata files in the [knowledgebase assets folder.](../packages/cdk_infra/src/assets/knowledgebase)

#### Using Metadata Filters

When querying your knowledge base, you can apply metadata filters in your API requests. Here are some examples:

Exact match filter:

```json
{
    "message": "Tell me about bedrock knowledge base quota",
    "metadata": {"equals": {"key": "service", "value": "bedrock"}}
}
```

Starts with filter:
```json
"metadata": {"startsWith": {"key": "service", "value": "bed"}}
```

Contains filter:
```json
"metadata": {"stringContains": {"key": "service", "value": "rock"}}
```

Not in filter: 
```json
"metadata": {"notIn": {"key": "service", "value": ["qbusiness", "lambda"]}}
```

Multiple conditions:
```json
"metadata": {
    "andAll":[
        {
            "greaterThan": {
                "key": "year", 
                "value": 2020
            }
        },
        {
            "lessThan":  {
            "key": "year", 
            "value": 2025
            }
        }
    ]
}
```

#### Response with Metadata

When you use metadata filtering, the API response will include citation information with the relevant metadata:

```json
{
    "sessionId": "21eb9dc5-eb6e-44d9-a131-a539a2e7d382",
    "message": "The following quotas apply to Knowledge bases for Amazon Bedrock: ...",
    "citations": [
        {
            "content": "The maximum number of text units that can be processed ...",
            "metadata": {
                "x-amz-bedrock-kb-source-uri": "s3://..file_name.pdf",
                "service": "bedrock"
            }
        }
    ]
}
```

## Best Practices

- Use meaningful and consistent metadata attributes across your documents.
- Keep metadata simple and relevant to your use case.
- Test different metadata filters to ensure they retrieve the expected information. 
 
For more details on metadata filtering options, refer to [the Amazon Bedrock documentation on Metadata and filtering.](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-config.html) 