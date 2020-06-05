locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # We'll use a shorter environment name in order to keep things simple
  short_environment = replace(var.environment, "apps-", "")

  # The name of the cluster
  base_domain_name = "binbash.aws"
  k8s_cluster_name = "cluster-kops-1.k8s.${local.short_environment}.${local.base_domain_name}"

  # The kubernetes version
  k8s_cluster_version = "1.14.10"

  # The etcd version
  # Ref1: https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md#etcdclusters-v3--tls
  # Ref2: https://github.com/etcd-io/etcd/releases
  etcd_clusters_version = "3.3.13"

  # The Calico Network CNI version
  # Ref1: https://github.com/kubernetes/kops/blob/master/docs/calico-v3.md
  # Ref2: Ref2: https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-36475925a560
  networking_calico_major_version = "v3"

  # Kops AMI Identifier
  kops_ami_id = "kope.io/k8s-1.14-debian-stretch-amd64-hvm-ebs-2019-09-26"

  # Tags that will be applied to all K8s Kops cluster instances
  cluster_tags = {
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "owned"
  }

  # Tags that will be applied to all K8s Kops Worker nodes
  node_cloud_labels = {}

  # K8s Kops Master Nodes Machine (EC2) type and size + ASG Min-Max per AZ
  # then min/max = 1 will create 1 Master Node x AZ => 3 x Masters
  kops_master_machine_type     = "t2.large"
  kops_master_machine_max_size = 1
  kops_master_machine_min_size = 1

  # K8s Kops Worker Nodes Machine (EC2) type and size + ASG Min-Max
  kops_worker_machine_type     = "t2.medium"
  kops_worker_machine_max_size = 5
  kops_worker_machine_min_size = 2
}
