/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as path from "path";
import { Stack, StackProps, RemovalPolicy, CfnOutput } from "aws-cdk-lib";
import * as glue from "aws-cdk-lib/aws-glue";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as s3deploy from "aws-cdk-lib/aws-s3-deployment";
import { Construct } from "constructs";

interface AthenaStackProps extends StackProps {
  ACCESS_LOG_BUCKET: s3.Bucket;
}

export class AthenaStack extends Stack {
  public readonly ATHENA_OUTPUT_BUCKET: s3.Bucket;
  public readonly ATHENA_DATA_BUCKET: s3.Bucket;
  public readonly ATHENA_DATABASE: glue.CfnDatabase;

  constructor(scope: Construct, id: string, props: AthenaStackProps) {
    super(scope, id, props);

    // Create S3 buckets for Athena
    this.ATHENA_DATA_BUCKET = new s3.Bucket(this, "AthenaDataBucket", {
      bucketName: `sl-data-store-${this.account}-${this.region}`,
      enforceSSL: true,
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      serverAccessLogsBucket: props.ACCESS_LOG_BUCKET,
      serverAccessLogsPrefix: "athena-data-bucket-logs/",
    });

    this.ATHENA_OUTPUT_BUCKET = new s3.Bucket(this, "AthenaOutputBucket", {
      bucketName: `sl-athena-output-${this.account}-${this.region}`,
      enforceSSL: true,
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      serverAccessLogsBucket: props.ACCESS_LOG_BUCKET,
      serverAccessLogsPrefix: "athena-output-bucket-logs/",
    });

    // Upload a sample csv file for Products table
    new s3deploy.BucketDeployment(this, "DeployProductsSampleTable", {
      sources: [
        s3deploy.Source.asset(path.join(__dirname, "..", "..", "assets", "products")),
      ],
      destinationBucket: this.ATHENA_DATA_BUCKET,
      destinationKeyPrefix: "products",
    });

    // Upload a sample csv file for Reviews table
    new s3deploy.BucketDeployment(this, "DeployReviewsSampleTable", {
      sources: [
        s3deploy.Source.asset(path.join(__dirname, "..", "..", "assets", "reviews")),
      ],
      destinationBucket: this.ATHENA_DATA_BUCKET,
      destinationKeyPrefix: "reviews",
    });

    // Create Athena Database
    this.ATHENA_DATABASE = new glue.CfnDatabase(this, "AthenaDatabase", {
      catalogId: this.account,
      databaseInput: {
        name: "ecommerce_data",
      },
    });

    // Create Glue Tables
    new glue.CfnTable(this, "ProductsTable", {
      catalogId: this.account,
      databaseName: "ecommerce_data",
      tableInput: {
        name: "products",
        // Define your columns here
        storageDescriptor: {
          columns: [
            {
              name: "product_id",
              type: "int",
              comment: "Unique identifier for each product",
            },
            {
              name: "product_name",
              type: "string",
              comment: "Name of the product",
            },
            {
              name: "category",
              type: "string",
              comment: "Category the product belongs to",
            },
            {
              name: "price",
              type: "decimal(10,2)",
              comment: "Price of the product",
            },
            {
              name: "description",
              type: "string",
              comment: "Detailed description of the product",
            },
            {
              name: "created_at",
              type: "timestamp",
              comment: "Timestamp when product was created",
            },
            {
              name: "updated_at",
              type: "timestamp",
              comment: "Timestamp when product was last updated",
            },
          ],
          location: `s3://${this.ATHENA_DATA_BUCKET.bucketName}/products`,
          inputFormat: "org.apache.hadoop.mapred.TextInputFormat",
          outputFormat:
            "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
          serdeInfo: {
            serializationLibrary:
              "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
            parameters: {
              "field.delim": ",", // Specify the field delimiter as pipe (|)
              // "serialization.format": "|",  // Set serialization format to match field delimiter
              // "escapeChar": "\\", // Define escape character for special characters
              "line.delim": "\n", // Specify line delimiter as newline character
            },
          },
        },
        tableType: "EXTERNAL_TABLE",
        parameters: {
          "skip.header.line.count": "1", // Skip the first line (header) when reading the file
        },
      },
    });

    new glue.CfnTable(this, "ReviewsTable", {
      catalogId: this.account,
      databaseName: "ecommerce_data",
      tableInput: {
        name: "reviews",
        storageDescriptor: {
          columns: [
            {
              name: "review_id",
              type: "int",
              comment: "Unique identifier for each review",
            },
            {
              name: "product_id",
              type: "int",
              comment: "Foreign key referencing the product",
            },
            {
              name: "customer_name",
              type: "string",
              comment: "Name of the customer who left the review",
            },
            {
              name: "rating",
              type: "int",
              comment: "Rating given by the customer (e.g., 1-5)",
            },
            {
              name: "comment",
              type: "string",
              comment: "Text of the review",
            },
            {
              name: "review_date",
              type: "timestamp",
              comment: "Date and time when the review was submitted",
            },
          ],
          location: `s3://${this.ATHENA_DATA_BUCKET.bucketName}/reviews`,
          inputFormat: "org.apache.hadoop.mapred.TextInputFormat",
          outputFormat: "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
          serdeInfo: {
            serializationLibrary: "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
            parameters: {
              "field.delim": ",",
              "line.delim": "\n",
            },
          },
        },
        tableType: "EXTERNAL_TABLE",
        parameters: {
          "skip.header.line.count": "1",
        },
      },
    });

    // Outputs
    new CfnOutput(this, "AthenaDataBucketName", {
      value: this.ATHENA_DATA_BUCKET.bucketName,
      description: "Athena Data Bucket Name",
    });

    new CfnOutput(this, "AthenaOutputBucketName", {
      value: this.ATHENA_OUTPUT_BUCKET.bucketName,
      description: "Athena Output Bucket Name",
    });

    new CfnOutput(this, "AthenaDatabaseName", {
      value: this.ATHENA_DATABASE.ref,
      description: "Athena Database Name",
    });
  }
}
