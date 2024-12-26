data "sql_query" "mysql_create_table" {
  provider = sql.mysql
  query    = <<EOT
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
  query    = <<EOT
         INSERT INTO sockshop_products (product_id, name, color, price) VALUES
         (null, 'Red Socks', 'Red', 9.99),
         (null, 'Blue Socks', 'Blue', 8.99),
         (null, 'Green Socks', 'Green', 7.99);
      EOT

  depends_on = [data.sql_query.mysql_create_table]
}

data "sql_query" "postgres_create_table" {
  provider = sql.postgres
  query    = <<EOT
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
  query    = <<EOT
              INSERT INTO sockshop_orders (product_id, quantity, order_date, total) VALUES
              (1, 2, '2024-11-01', 19.98),
              (2, 1, '2024-11-02', 8.99),
              (3, 3, '2024-11-03', 23.97)
              ON CONFLICT (order_id) DO NOTHING;

      EOT

  depends_on = [data.sql_query.postgres_create_table]
}