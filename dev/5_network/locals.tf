locals {
    tags = {
        Terraform = "true"
        Environment = "${var.environment}"
    }

    # Network Local Vars
    vpc_name = "${var.project}-${var.environment}-vpc"
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

    #
    # PLACEHOLDER DNS RELATED VARs - CURRENTLY NOT IN USE
    #
    # Ingress ALB used for Dev/Stg Ingress ALB
    dev_k8s_ingress_alb_id = "internal-kube-ing-LB-XXXXXXXXXXXX-YYYYYYYYYY.us-east-1.elb.amazonaws.com"
    dev_k8s_ingress_alb_zone = "Z3AAXXXXXXXXX"
    
    # Ingress ALB used for Prd Ingress ALB
    prd_k8s_ingress_alb_id = "kube-ing-LB-XXXXXXXXXXXXX-YYYYYYYYYY.us-east-1.elb.amazonaws.com"
    prd_k8s_ingress_alb_zone = "Z3AAXXXXXXXXX"
}