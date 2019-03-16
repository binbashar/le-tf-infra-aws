locals {
    tags = {
        Terraform = "true"
        Environment = "${var.environment}"
    }
    vpc_name = "${var.project}-apps-${var.environment}-vpc"
    vpc_cidr_block = "172.17.32.0/20"
    azs = ["us-east-1a", "us-east-1b"]
    private_subnets = [
        "172.17.32.0/23",
        "172.17.34.0/23"
    ]
    public_subnets = [
        "172.17.38.0/23",
        "172.17.40.0/23"
    ]
}