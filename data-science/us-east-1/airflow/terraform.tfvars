#=============================#
# MWAA Configuration          #
#=============================#

# Airflow version
airflow_version = "2.10.1"

# Environment class (mw1.micro, mw1.small, mw1.medium, mw1.large, mw1.xlarge, mw1.2xlarge)
environment_class = "mw1.small"

# Worker configuration
min_workers = 1
max_workers = 10
schedulers  = 2

# Webserver access mode (PRIVATE_ONLY or PUBLIC_ONLY)
webserver_access_mode = "PRIVATE_ONLY"

# S3 paths
dag_s3_path = "dags"

# Logging configuration
enable_logging = true
log_level      = "INFO"
