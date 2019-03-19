locals {
    tags = {
        Terraform = "true"
        Environment = "${var.environment}"
    }
    
    # Ingress ALB used for Dev/Stg Ingress ALB
    dev_k8s_ingress_alb_id = "internal-kube-ing-LB-XXXXXXXXXXXX-YYYYYYYYYY.us-east-1.elb.amazonaws.com"
    dev_k8s_ingress_alb_zone = "Z3AADJGX6KTTL2"
    
    # Ingress ALB used for Prd Ingress ALB
    prd_k8s_ingress_alb_id = "kube-ing-LB-XXXXXXXXXXXXX-YYYYYYYYYY.us-east-1.elb.amazonaws.com"
    prd_k8s_ingress_alb_zone = "Z3AADJGX6KTTL2"
}