import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { NagSuppressions } from 'cdk-nag';
import { BedrockDocumentProcessingStack } from './bedrock-bda-agent-stack';
import { CommonStack } from '../common-stack';
import { BedrockKnowledgeBaseStack } from '../bedrock-kb-stack';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as stepfunctions from 'aws-cdk-lib/aws-stepfunctions';
import * as tasks from 'aws-cdk-lib/aws-stepfunctions-tasks';
import { RemovalPolicy } from 'aws-cdk-lib';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import { PythonFunction } from '@aws-cdk/aws-lambda-python-alpha';
import * as path from 'path';
import { Duration } from 'aws-cdk-lib';
import * as ssm from 'aws-cdk-lib/aws-ssm';

interface DocumentProcessingStackProps extends cdk.StackProps {
  env: cdk.Environment;
  stackNamePrefix: string;
  commonStack: CommonStack;
  bedrockKnowledgeBaseStack?: BedrockKnowledgeBaseStack;
  KYB_ENABLED?: boolean;
}

export class DocumentProcessingStack extends cdk.Stack {
  public readonly INPUT_BUCKET: s3.Bucket;
  public readonly OUTPUT_BUCKET: s3.Bucket;
  public readonly METADATA_TABLE: dynamodb.Table;
  public readonly KYB_WORKFLOW?: stepfunctions.StateMachine;

  constructor(
    scope: Construct,
    id: string,
    props: DocumentProcessingStackProps,
  ) {
    super(scope, id, props);

    // Create S3 buckets
    this.INPUT_BUCKET = new s3.Bucket(this, "InputBucket", {
      enforceSSL: true,
      versioned: true,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.HEAD, s3.HttpMethods.PUT, s3.HttpMethods.POST],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
          exposedHeaders: ['Access-Control-Allow-Origin']
        }
      ]
    });

    this.OUTPUT_BUCKET = new s3.Bucket(this, "OutputBucket", {
      enforceSSL: true,
      versioned: true,
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.HEAD],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
          exposedHeaders: ['Access-Control-Allow-Origin']
        }
      ]
    });

    // Create DynamoDB table for document metadata
    this.METADATA_TABLE = new dynamodb.Table(this, 'MetadataTable', {
      partitionKey: { name: 'documentId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'pageNumber', type: dynamodb.AttributeType.NUMBER },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: RemovalPolicy.DESTROY,
      pointInTimeRecovery: true,
    });

    // Add GSI for status tracking
    this.METADATA_TABLE.addGlobalSecondaryIndex({
      indexName: 'StatusIndex',
      partitionKey: { name: 'status', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'lastUpdated', type: dynamodb.AttributeType.STRING },
    });

    // Add KYB-specific GSIs if enabled
    if (props.KYB_ENABLED) {
      this.METADATA_TABLE.addGlobalSecondaryIndex({
        indexName: 'documentTypeIndex',
        partitionKey: { name: 'documentType', type: dynamodb.AttributeType.STRING },
        sortKey: { name: 'status', type: dynamodb.AttributeType.STRING },
        projectionType: dynamodb.ProjectionType.ALL,
      });

      this.METADATA_TABLE.addGlobalSecondaryIndex({
        indexName: 'entityIndex',
        partitionKey: { name: 'entityId', type: dynamodb.AttributeType.STRING },
        sortKey: { name: 'documentType', type: dynamodb.AttributeType.STRING },
        projectionType: dynamodb.ProjectionType.ALL,
      });

      // Add KYB-specific folder structure
      new s3deploy.BucketDeployment(this, 'CreateKYBFolders', {
        sources: [s3deploy.Source.data('kyb/', '')],
        destinationBucket: this.INPUT_BUCKET,
        destinationKeyPrefix: 'kyb',
      });
    }

    // Grant S3 permissions to Cognito authenticated users
    const s3PolicyDocument = new iam.PolicyDocument({
      statements: [
        new iam.PolicyStatement({
          actions: [
            's3:PutObject',
            's3:GetObject',
            's3:ListBucket',
            's3:DeleteObject'
          ],
          resources: [
            this.INPUT_BUCKET.bucketArn,
            `${this.INPUT_BUCKET.bucketArn}/*`
          ],
          effect: iam.Effect.ALLOW,
        }),
        new iam.PolicyStatement({
          actions: [
            's3:GetObject',
            's3:ListBucket'
          ],
          resources: [
            this.OUTPUT_BUCKET.bucketArn,
            `${this.OUTPUT_BUCKET.bucketArn}/*`
          ],
          effect: iam.Effect.ALLOW,
        }),
      ],
    });

    // Add the policy document to the authenticated role in the Identity Pool
    props.commonStack.USER_IDENTITY.identityPool.authenticatedRole.attachInlinePolicy(
      new iam.Policy(this, "document-processing-s3-access-policy", {
        document: s3PolicyDocument,
      }),
    );

    // Note the difference here - pass in the bucket names as string arguments
    // instead of the bucket objects themselves, to avoid circular dependencies
    const bedrockStack = new BedrockDocumentProcessingStack(this, `DocumentProcessingStack`, {
      env: props.env,
      LAYER_POWERTOOLS: props.commonStack.LAYER_POWERTOOLS,
      LAYER_BOTO: props.commonStack.LAYER_BOTO,
      LAYER_PYDANTIC: props.commonStack.LAYER_PYDANTIC,
      // Pass bucket names (strings) instead of bucket objects to avoid circular dependencies
      INPUT_BUCKET_NAME: this.INPUT_BUCKET.bucketName,
      OUTPUT_BUCKET_NAME: this.OUTPUT_BUCKET.bucketName,
      METADATA_TABLE_NAME: this.METADATA_TABLE.tableName,
      KYB_ENABLED: props.KYB_ENABLED,
    });

    // Create KYB Agent Lambda for document processing
    // This Lambda will be independent of the Bedrock Agent creation
    const kybAgentLambda = new PythonFunction(this, 'KYBAgentLambda', {
      functionName: `KYBAgent-${cdk.Names.uniqueId(this).substring(0, 8)}`,
      entry: path.join(__dirname, '../../backend/agents/lambda/kyb_agent'),
      index: 'kyb_agent.py',
      handler: 'lambda_handler',
      runtime: lambda.Runtime.PYTHON_3_11,
      timeout: Duration.minutes(15),
      memorySize: 1024,
      layers: [
        props.commonStack.LAYER_POWERTOOLS,
        props.commonStack.LAYER_BOTO,
      ],
      environment: {
        // Store only bucket and table names, not direct references to resources
        'INPUT_BUCKET': this.INPUT_BUCKET.bucketName,
        'OUTPUT_BUCKET': this.OUTPUT_BUCKET.bucketName,
        'BDA_PROJECT_ID': bedrockStack.BEDROCK_DATA_AUTOMATION_PROJECT_ID,
        // We'll let the Lambda find the agent ID at runtime
        'REGION': this.region,
        'AGENT_NAME_PREFIX': `${id.replace('/', '-')}-KYBAgent`,
        'AGENT_ALIAS_ID': 'DRAFT',
      },
    });

    // Grant necessary permissions to the KYB Agent Lambda
    this.INPUT_BUCKET.grantRead(kybAgentLambda);
    this.OUTPUT_BUCKET.grantReadWrite(kybAgentLambda);
    this.METADATA_TABLE.grantReadWriteData(kybAgentLambda);
    
    // Grant permissions to list and describe agents
    kybAgentLambda.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'bedrock:ListAgents',
        'bedrock:GetAgent',
        'bedrock:InvokeAgent',
        'bedrock:ListDataIntegrationFlows',
        'bedrock:InvokeDataAutomationAsync',
        'bedrock:GetDataAutomationStatus',
        'bedrock:GetDataAutomationResults'
      ],
      resources: ['*'],
    }));

    // Create API Gateway for KYB document processing
    // Using proper API Gateway integration with CORS
    const api = new apigateway.RestApi(this, 'KYBDocumentProcessingApi', {
      restApiName: 'KYB Document Processing API',
      description: 'API for KYB document processing',
      deployOptions: {
        stageName: 'prod',
        throttlingRateLimit: 10,
        throttlingBurstLimit: 20,
        loggingLevel: apigateway.MethodLoggingLevel.INFO,
        dataTraceEnabled: true,
        metricsEnabled: true,
      },
      // Don't use defaultCorsPreflightOptions as we need more control
      // We'll manually set up CORS for each method
    });

    // Create Cognito User Pool authorizer for the API
    const cognitoAuthorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'KYBCognitoAuthorizer', {
      cognitoUserPools: [props.commonStack.USER_IDENTITY.userPool],
      identitySource: 'method.request.header.Authorization',
    });

    // Create root resource with proper path matching for frontend
    const apiResource = api.root;
    const apiKybResource = apiResource.addResource('api').addResource('kyb');
    const processResource = apiKybResource.addResource('process');
    
    // Add OPTIONS method without authorization - critical for CORS preflight requests
    const optionsMethod = processResource.addMethod('OPTIONS', new apigateway.MockIntegration({
      integrationResponses: [{
        statusCode: '200',
        responseParameters: {
          'method.response.header.Access-Control-Allow-Headers': "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
          'method.response.header.Access-Control-Allow-Methods': "'OPTIONS,POST,GET'",
          'method.response.header.Access-Control-Allow-Origin': "'*'"
        }
      }],
      passthroughBehavior: apigateway.PassthroughBehavior.NEVER,
      requestTemplates: {
        'application/json': '{"statusCode": 200}'
      }
    }), {
      methodResponses: [{
        statusCode: '200',
        responseParameters: {
          'method.response.header.Access-Control-Allow-Headers': true,
          'method.response.header.Access-Control-Allow-Methods': true,
          'method.response.header.Access-Control-Allow-Origin': true
        }
      }]
    });

    // Add POST method with Cognito authorizer and CORS response headers
    const integration = new apigateway.LambdaIntegration(kybAgentLambda, {
      proxy: true,
      integrationResponses: [
        {
          statusCode: '200',
          responseParameters: {
            'method.response.header.Access-Control-Allow-Origin': "'*'",
          }
        }
      ]
    });

    processResource.addMethod('POST', integration, {
      authorizer: cognitoAuthorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
      methodResponses: [
        {
          statusCode: '200',
          responseParameters: {
            'method.response.header.Access-Control-Allow-Origin': true,
          }
        }
      ]
    });

    // Output the API URL and important resource names
    new cdk.CfnOutput(this, 'KYBApiEndpoint', {
      value: api.url,
      description: 'URL of the KYB document processing API',
    });
    
    new cdk.CfnOutput(this, 'InputBucketName', {
      value: this.INPUT_BUCKET.bucketName,
      description: 'Name of the S3 bucket for document input',
      exportName: `${id.replace('/', '-')}-InputBucketName`,
    });

    new cdk.CfnOutput(this, 'OutputBucketName', {
      value: this.OUTPUT_BUCKET.bucketName,
      description: 'Name of the S3 bucket for document output',
      exportName: `${id.replace('/', '-')}-OutputBucketName`,
    });

    // Create KYB workflow if enabled - adapted to use direct resource names
    if (props.KYB_ENABLED) {
      // Define the KYB workflow steps
      const startKYBWorkflow = new stepfunctions.Pass(this, 'StartKYBWorkflow', {
        result: { value: 'Starting KYB document processing' },
        resultPath: '$.initialState'
      });

      // Get Lambda function ARN from name
      const getDocumentProcessingFunctionArn = () => {
        return `arn:aws:lambda:${this.region}:${this.account}:function:DocProcess-${cdk.Names.uniqueId(bedrockStack).substring(0, 8)}`;
      };

      // Create Lambda functions to interact with
      const lambdaInvokeRole = new iam.Role(this, 'LambdaInvokeRole', {
        assumedBy: new iam.ServicePrincipal('states.amazonaws.com'),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaRole')
        ]
      });

      // Create the workflow using function names instead of direct references
      const checkDocumentType = new stepfunctions.Choice(this, 'CheckDocumentType')
        .when(stepfunctions.Condition.stringEquals('$.documentType', 'ein_verification'), 
          new tasks.LambdaInvoke(this, 'ProcessEINVerification', {
            lambdaFunction: lambda.Function.fromFunctionArn(
              this, 
              'DocProcessFunctionEIN', 
              getDocumentProcessingFunctionArn()
            ),
            payload: stepfunctions.TaskInput.fromObject({
              'documentType': 'ein_verification',
              's3Key': stepfunctions.JsonPath.stringAt('$.s3Key'),
              'entityId': stepfunctions.JsonPath.stringAt('$.entityId')
            }),
            resultPath: '$.processingResult'
          }))
        // Add other document type handlers as needed
        .otherwise(new stepfunctions.Fail(this, 'UnsupportedDocumentType', {
          error: 'UnsupportedDocumentType',
          cause: 'The provided document type is not supported for KYB processing'
        }));

      // Define a simplified workflow
      const definition = startKYBWorkflow
        .next(checkDocumentType);

      // Create the state machine
      this.KYB_WORKFLOW = new stepfunctions.StateMachine(this, 'KYBWorkflow', {
        definition,
        timeout: cdk.Duration.minutes(30),
        tracingEnabled: true,
        stateMachineType: stepfunctions.StateMachineType.EXPRESS,
      });

      // Grant necessary permissions using resource ARNs
      lambdaInvokeRole.addToPolicy(new iam.PolicyStatement({
        actions: ['lambda:InvokeFunction'],
        resources: [getDocumentProcessingFunctionArn()]
      }));

      this.METADATA_TABLE.grantReadWriteData(this.KYB_WORKFLOW);
      this.INPUT_BUCKET.grantRead(this.KYB_WORKFLOW);
      this.OUTPUT_BUCKET.grantWrite(this.KYB_WORKFLOW);

      // Configure S3 event trigger for the KYB workflow
      const rule = new events.Rule(this, 'KYBUploadRule', {
        eventPattern: {
          source: ['aws.s3'],
          detailType: ['Object Created'],
          detail: {
            bucket: {
              name: [this.INPUT_BUCKET.bucketName],
            },
            object: {
              key: [{ prefix: 'kyb/' }],
            },
          },
        },
      });

      rule.addTarget(new targets.SfnStateMachine(this.KYB_WORKFLOW, {
        input: events.RuleTargetInput.fromObject({
          bucket: events.EventField.fromPath('$.detail.bucket.name'),
          key: events.EventField.fromPath('$.detail.object.key'),
          documentType: events.EventField.fromPath('$.detail.object.key').split('/')[1],
          entityId: events.EventField.fromPath('$.detail.object.key').split('/')[2],
        }),
      }));
    }

    // Suppress CDK-nag warnings for bucket policies
    NagSuppressions.addResourceSuppressionsByPath(
      this,
      `/${id}/InputBucket/Resource`,
      [
        {
          id: 'AwsSolutions-S1',
          reason: 'Access logs not required for this demo bucket',
        },
      ],
    );

    NagSuppressions.addResourceSuppressionsByPath(
      this,
      `/${id}/OutputBucket/Resource`,
      [
        {
          id: 'AwsSolutions-S1',
          reason: 'Access logs not required for this demo bucket',
        },
      ],
    );
    
    // Suppress authorization warnings for OPTIONS method (needed for CORS preflight)
    NagSuppressions.addResourceSuppressionsByPath(
      this,
      `/${id}/KYBDocumentProcessingApi/Default/api/kyb/process/OPTIONS/Resource`,
      [
        {
          id: 'AwsPrototyping-APIGWAuthorization',
          reason: 'OPTIONS method must not have authorization for CORS preflight requests to work',
        },
        {
          id: 'AwsPrototyping-CognitoUserPoolAPIGWAuthorizer',
          reason: 'OPTIONS method must not have authorization for CORS preflight requests to work',
        },
      ],
    );
  }
}