/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as path from "path";
import { PythonLayerVersion } from "@aws-cdk/aws-lambda-python-alpha";
import * as apigateway from "aws-cdk-lib/aws-apigateway";
import * as iam from "aws-cdk-lib/aws-iam";
import * as lambda from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";

export interface OrderProcessingRestApiExampleProps {
  LAYER_BOTO: PythonLayerVersion;
}

export class OrderProcessingRestApiExample extends Construct {
  constructor(
    scope: Construct,
    id: string,
    _props: OrderProcessingRestApiExampleProps,
  ) {
    super(scope, id);

    // * AWS Lambda
    let orderProcessingLambdaDir =
      "src/backend/rest_apis/order_processing_example/lambda";

    // Lambda Functions that serve as the backend of the Order Processing Example Rest API
    const cancelOrderRestApiBackend = new lambda.Function(
      this,
      "CancelOrderRestApiBackend",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        code: lambda.Code.fromAsset(
          path.join(orderProcessingLambdaDir, "cancel_order"),
        ),
        handler: "cancel_order.handler",
      },
    );

    const orderStatusRestApiBackend = new lambda.Function(
      this,
      "OrderStatusRestApiBackend",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        code: lambda.Code.fromAsset(
          path.join(orderProcessingLambdaDir, "order_status"),
        ),
        handler: "order_status.handler",
      },
    );

    const estimatedDeliveryRestApiBackend = new lambda.Function(
      this,
      "EstimatedDeliveryRestApiBackend",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        code: lambda.Code.fromAsset(
          path.join(orderProcessingLambdaDir, "estimated_delivery"),
        ),
        handler: "estimated_delivery.handler",
      },
    );

    const searchRestApiBackend = new lambda.Function(
      this,
      "SearchRestApiBackend",
      {
        runtime: lambda.Runtime.PYTHON_3_11,
        code: lambda.Code.fromAsset(
          path.join(orderProcessingLambdaDir, "search"),
        ),
        handler: "search.handler",
      },
    );

    // * Amazon API Gateway

    // Example Rest API for Order Management
    const orderProcessingRestApi = new apigateway.RestApi(
      this,
      "OrderProcessingRestApi",
      {
        restApiName: "OrderProcessingRestApi",
        description:
          "Example Rest API for Order Processing with an AWS Lambda Backend",
      },
    );

    // API gateway policy statement
    new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      resources: ["*"],
      actions: ["execute-api:Invoke"],
      principals: [new iam.AnyPrincipal()],
    });

    // Define the API Gateway resources and methods
    const cancelOrderResource = orderProcessingRestApi.root.addResource(
      "CancelOrderResource",
      {
        defaultCorsPreflightOptions: {
          allowOrigins: apigateway.Cors.ALL_ORIGINS,
          allowMethods: apigateway.Cors.ALL_METHODS,
        },
      },
    );
    cancelOrderResource.addMethod(
      "POST",
      new apigateway.LambdaIntegration(cancelOrderRestApiBackend),
    );

    const orderStatusResource = orderProcessingRestApi.root.addResource(
      "OrderStatusResource",
      {
        defaultCorsPreflightOptions: {
          allowOrigins: apigateway.Cors.ALL_ORIGINS,
          allowMethods: apigateway.Cors.ALL_METHODS,
        },
      },
    );
    orderStatusResource.addMethod(
      "GET",
      new apigateway.LambdaIntegration(orderStatusRestApiBackend),
    );

    const estimatedDeliveryResource = orderProcessingRestApi.root.addResource(
      "EstimatedDeliveryResource",
      {
        defaultCorsPreflightOptions: {
          allowOrigins: apigateway.Cors.ALL_ORIGINS,
          allowMethods: apigateway.Cors.ALL_METHODS,
        },
      },
    );
    estimatedDeliveryResource.addMethod(
      "POST",
      new apigateway.LambdaIntegration(estimatedDeliveryRestApiBackend),
    );

    const searchResource = orderProcessingRestApi.root.addResource(
      "SearchResource",
      {
        defaultCorsPreflightOptions: {
          allowOrigins: apigateway.Cors.ALL_ORIGINS,
          allowMethods: apigateway.Cors.ALL_METHODS,
        },
      },
    );
    searchResource.addMethod(
      "POST",
      new apigateway.LambdaIntegration(searchRestApiBackend),
    );

    // Deploy the API Gateway
    new apigateway.Deployment(this, "Deployment", {
      api: orderProcessingRestApi,
      retainDeployments: true,
    });
  }
}
