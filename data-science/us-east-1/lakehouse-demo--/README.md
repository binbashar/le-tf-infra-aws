# Lakehouse Demo

## Introduction
A **lakehouse** is a modern data architecture that combines the best features of data lakes and data warehouses. It provides the scalability and flexibility of data lakes while ensuring data governance, reliability, and ACID transactions like a traditional data warehouse.

### Advantages of a Lakehouse Architecture
- **Unified Storage**: Combines structured and unstructured data in a single platform.
- **Reliability**: Supports ACID transactions for consistency.
- **Performance**: Optimized query performance with indexing and caching.
- **Cost-Effective**: Reduces storage and processing costs compared to traditional warehouses.
- **Scalability**: Can handle massive amounts of data efficiently.
- **Support for Multiple Workloads**: Works for BI, machine learning, and real-time analytics.

## Prerequisites
Before applying the Terraform code in this folder, ensure that the **datalake-demo** layer has been successfully deployed. The lakehouse depends on resources created in the data lake layer.

## Deployment Instructions
1. Navigate to the `datalake-demo` directory and apply the Terraform code:
   ```sh
   cd ../datalake-demo
   leverage terraform init
   leverage terraform apply
   ```
2. Once the **datalake-demo** deployment is complete, navigate to `lakehouse-demo`:
   ```sh
   cd ../lakehouse-demo
   ```
3. Initialize and apply the Terraform code for the lakehouse:
   ```sh
   leverage terraform init
   leverage terraform apply
   ```

## Expected Result
Once we run `leverage terraform apply`, the following components are **automatically deployed and populated**:

1. **Databases**:
   - The **MySQL database** is populated with **sock products**.
   - The **PostgreSQL database** is populated with **orders** (buys referencing the MySQL product table).

2. **Data Movement & Processing**:
   - **AWS DMS** reads from both databases and stores the data in **S3**.
   - **ETL processes** transform and combine the data from both sources, creating a new layer that relates each **product** to the **sum of its orders**.

3. **Data Querying**:
   - **Amazon Redshift** queries the data from the external schema **'awsdatacatalog'** (**'sales'** database), reading directly from **S3**.

## Notes
- Ensure you have the required AWS credentials configured.
- Review and adjust the Terraform variables as needed before applying changes.
- Destroy resources in reverse order: first `lakehouse-demo`, then `datalake-demo`, to avoid dependency issues.

## Conclusion
This setup demonstrates how to build a **lakehouse** on top of a **data lake**, leveraging the strengths of both architectures to enable efficient and scalable data processing.