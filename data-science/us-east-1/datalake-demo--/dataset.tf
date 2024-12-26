# resource "null_resource" "mysql_data_insertion" {

#   provisioner "local-exec" {
#     command = <<EOT
#       #!/bin/bash
#       set -e
#       # Variables
#         DB_CLUSTER_ARN=${data.terraform_remote_state.aurora_mysql.outputs.cluster_arn}
#         SECRET_ARN=${data.terraform_remote_state.secrets.outputs.secret_arns["/aurora-mysql/administrator"]}
#         MYSQL_DATABASE=${data.terraform_remote_state.aurora_mysql.outputs.cluster_database_name}
#         export AWS_PROFILE=bb-data-science-devops
#         export AWS_CONFIG_FILE=/home/leverage/tmp/bb/config
#         export AWS_SHARED_CREDENTIALS_FILE=/home/leverage/tmp/bb/credentials
#         export AWS_REGION=us-east-1

#         create_table_sql="CREATE TABLE IF NOT EXISTS sockshop_products (
#         product_id INT PRIMARY KEY,
#         name VARCHAR(100),
#         color VARCHAR(50),
#         price DECIMAL(10, 2)
#         );"

#         # Insert some sock products
#         insert_data_sql="INSERT INTO sockshop_products (product_id, name, color, price) VALUES
#         (1, 'Red Socks', 'Red', 9.99),
#         (2, 'Blue Socks', 'Blue', 8.99),
#         (3, 'Green Socks', 'Green', 7.99);"

#         # Execute CREATE TABLE
#         aws rds-data execute-statement \
#         --resource-arn "$DB_CLUSTER_ARN" \
#         --secret-arn "$SECRET_ARN" \
#         --database "$MYSQL_DATABASE" \
#         --sql "$create_table_sql"

#         # Execute INSERT INTO
#         aws rds-data execute-statement \
#         --resource-arn "$DB_CLUSTER_ARN" \
#         --secret-arn "$SECRET_ARN" \
#         --database "$MYSQL_DATABASE" \
#         --sql "$insert_data_sql"
#     EOT
#   }
# }

# # PostgreSQL Data Insertion using local-exec
# resource "null_resource" "postgres_data_insertion" {

#   triggers = {
#     always_run = timestamp()
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       #!/bin/bash
#       set -e
#       # Variables
#         DB_CLUSTER_ARN=${data.terraform_remote_state.aurora_postgres.outputs.cluster_arn}
#         SECRET_ARN=${data.terraform_remote_state.secrets_apps_devstg.outputs.secret_arns["/aurora-pgsql/administrator"]}
#         POSTGRESQL_DATABASE=${data.terraform_remote_state.aurora_postgres.outputs.cluster_database_name}
#         export AWS_PROFILE=bb-apps-devstg-devops
#         export AWS_CONFIG_FILE=/home/leverage/tmp/bb/config
#         export AWS_SHARED_CREDENTIALS_FILE=/home/leverage/tmp/bb/credentials
#         export AWS_REGION=us-east-1


#         create_table_sql="CREATE TABLE IF NOT EXISTS sockshop_orders (
#               order_id SERIAL PRIMARY KEY,
#               product_id INT,
#               quantity INT,
#               order_date DATE,
#               total DECIMAL(10, 2)
#           );"

#           insert_data_sql="INSERT INTO sockshop_orders (product_id, quantity, order_date, total) VALUES
#               (1, 2, '2024-11-01', 19.98),
#               (2, 1, '2024-11-02', 8.99),
#               (3, 3, '2024-11-03', 23.97)
#           ON CONFLICT (order_id) DO NOTHING;"



#         # Execute CREATE TABLE
#         aws rds-data execute-statement \
#         --resource-arn "$DB_CLUSTER_ARN" \
#         --secret-arn "$SECRET_ARN" \
#         --database "$POSTGRESQL_DATABASE" \
#         --sql "$create_table_sql"

#         # Execute INSERT INTO
#         aws rds-data execute-statement \
#         --resource-arn "$DB_CLUSTER_ARN" \
#         --secret-arn "$SECRET_ARN" \
#         --database "$POSTGRESQL_DATABASE" \
#         --sql "$insert_data_sql"
        
#     EOT
#   }
# }

data "sql_query" "mysql_create_table" {
  provider = sql.mysql
  query = <<EOT
        CREATE TABLE IF NOT EXISTS sockshop_products (
        product_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        color VARCHAR(50),
        price DECIMAL(10, 2)
        );
      EOT
}

data "sql_query" "mysql_insert_data" {
    provider = sql.mysql
    query = <<EOT
         INSERT INTO sockshop_products (product_id, name, color, price) VALUES
         (null, 'Red Socks', 'Red', 9.99),
         (null, 'Blue Socks', 'Blue', 8.99),
         (null, 'Green Socks', 'Green', 7.99);
      EOT
  
  depends_on = [ data.sql_query.mysql_create_table ]
  }

data "sql_query" "postgres_create_table" {
  provider = sql.postgres
  query = <<EOT
              CREATE TABLE IF NOT EXISTS sockshop_orders (
              order_id SERIAL PRIMARY KEY,
              product_id INT,
              quantity INT,
              order_date DATE,
              total DECIMAL(10, 2)
           );
      EOT
}

data "sql_query" "postgres_insert_data" {
    provider = sql.postgres
    query = <<EOT
              INSERT INTO sockshop_orders (product_id, quantity, order_date, total) VALUES
              (1, 2, '2024-11-01', 19.98),
              (2, 1, '2024-11-02', 8.99),
              (3, 3, '2024-11-03', 23.97)
              ON CONFLICT (order_id) DO NOTHING;

      EOT
  
  depends_on = [ data.sql_query.postgres_create_table ]
  }