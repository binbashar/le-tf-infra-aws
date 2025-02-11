# Text2SQL: AWS Athena Query Execution API

This project provides a serverless API for executing SQL queries on AWS Athena databases. 
It offers a streamlined interface for data analysts and applications to interact with data stored in Amazon S3.

The API supports executing queries, listing tables, and describing table schemas in Athena databases. 

## Repository Structure

```
.
└── packages
    └── cdk_infra
        └── src
            └── backend
                └── agents
                    └── lambda
                        └── text2sql
                            └── athena
                                ├── athena_actions
                                ├── athena_schema_reader
                                └── common
                                    └── python

```

### Key Files

- `athena/athena_actions/athena_actions.py`: Lambda function for executing Athena queries
- `athena/athena_schema_reader/athena_schema_reader.py`: Lambda function for reading Athena schema information
- `athena/common/python/athena_utils.py`: Utility functions for Athena operations
- `athena/common/python/error_utils.py`: Error handling utilities
- `athena/common/python/request_utils.py`: Request processing utilities
- `athena/common/python/response_utils.py`: Response formatting utilities

### Integration Points

- AWS Athena: For executing SQL queries on data stored in Amazon S3
- Amazon S3: For storing Athena query results

### Troubleshooting

For performance optimization:
- Monitor query execution time using CloudWatch metrics
- Implement appropriate partitioning and indexing strategies in Athena tables
