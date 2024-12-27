from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from pyspark.sql import functions as F

# Initialize Glue Context
glueContext = GlueContext(SparkContext.getOrCreate())

# Load raw data from S3 (multiple Parquet files)
products_df = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": ["s3://bb-data-science-data-lake-demo-data-raw-bucket/destinationdata/demoapps/sockshop_products/"]},  # Directory containing multiple Parquet files
    format="parquet"
)

orders_df = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": ["s3://bb-data-science-data-lake-demo-data-raw-bucket/destinationdata/public/sockshop_orders/"]},  # Directory containing multiple Parquet files
    format="parquet"
)

# Convert to Spark DataFrames for transformation
products = products_df.toDF()
orders = orders_df.toDF()

# Perform a join to combine product and order data
product_orders = products.join(orders, products.product_id == orders.product_id, "inner") \
    .select(products.product_id, products.name, products.price, orders.order_id, orders.quantity)

# Add a total_amount column per product
product_summary = product_orders.groupBy("product_id", "name") \
    .agg(F.sum("quantity").alias("total_products_sold"))

# Convert back to Glue DynamicFrame
transformed = DynamicFrame.fromDF(product_summary, glueContext, "transformed")

# Write transformed data to S3
glueContext.write_dynamic_frame.from_options(
    frame=transformed,
    connection_type="s3",
    connection_options={"path": "s3://bb-data-science-data-lake-demo-data-processed-bucket/product_order_summary/"},
    format="parquet"  # Output format can be parquet or csv
)