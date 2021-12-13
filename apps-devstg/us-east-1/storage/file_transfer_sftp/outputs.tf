# output "customers_buckets" {
#   description = "Customers' buckets"

#   value = {
#     for k, mod in module.customers_buckets : k => mod.s3_bucket_id
#   }
# }
