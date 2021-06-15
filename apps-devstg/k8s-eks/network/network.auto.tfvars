vpc_enable_nat_gateway = false

vpc_endpoints = {
  s3 = {
    service      = "s3"
    service_type = "Gateway"
  }
  dynamodb = {
    service      = "dynamodb"
    service_type = "Gateway"
  }
}
