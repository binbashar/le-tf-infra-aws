locals {
    tags = {
        Terraform   = "true"
        Environment = var.environment
    }
    
    # We'll use a shorter environment name in order to keep things simple
    short_environment   = replace(var.environment, "apps-", "")
    
    # The name of the cluster
    base_domain_name    = "binbash.aws"
    k8s_cluster_name    = "cluster-1.k8s.${local.short_environment}.${local.base_domain_name}"
    
    # The kubernetes version
    k8s_cluster_version = "1.13.11"
    
    # Kops AMI Identifier
    kops_ami_id         = "kope.io/k8s-1.12-debian-stretch-amd64-hvm-ebs-2019-06-21"
    
    # Tags that will be applied to all nodes
    node_cloud_labels   = {}
}