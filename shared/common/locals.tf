locals {
    tags = {
        Terraform = "true"
        Environment = "${var.environment}"
    }
    
    # Ingress ALB used for Dev/Stg Ingress ALB
    dev_k8s_ingress_alb_id = "internal-kube-ing-LB-P4XS6CUI8Y6A-1173397967.us-east-1.elb.amazonaws.com"
    dev_k8s_ingress_alb_zone = "Z3AADJGX6KTTL2"
    
    # Ingress ALB used for Prd Ingress ALB
    prd_k8s_ingress_alb_id = "kube-ing-LB-HRQ2RZ4RD5OL-86824082.us-east-1.elb.amazonaws.com"
    prd_k8s_ingress_alb_zone = "Z3AADJGX6KTTL2"
}