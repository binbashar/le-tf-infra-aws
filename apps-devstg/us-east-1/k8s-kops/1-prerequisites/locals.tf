locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # We'll use a shorter environment name in order to keep things simple
  short_environment = replace(var.environment, "apps-", "")

  # The name of the cluster
  # if gossip_cluster then base_domain_name must be k8s.local
  gossip_cluster   = true
  base_domain_name = "k8s.local"
  k8s_cluster_name = "canada01-kops.${local.short_environment}.${local.base_domain_name}"

  # The kubernetes version
  k8s_cluster_version = "1.28.9"

  # The etcd version
  # Ref1: https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md#etcdclusters-v3--tls
  # Ref2: https://github.com/etcd-io/etcd/releases
  etcd_clusters_version = "3.5.9"

  # The Calico Network CNI version
  # Ref1: https://github.com/kubernetes/kops/blob/master/docs/calico-v3.md
  # Ref2: https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-36475925a560
  networking_calico_major_version = "v3"

  # Kops AMI Identifier
  # check image in https://cloud-images.ubuntu.com/locator/ec2/ , look for your zone.
  kops_ami_id = "ami-04fea581fe25e2675"

  # Tags that will be applied to all K8s Kops cluster instances
  cluster_tags = {
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "owned"
  }

  # Tags that will be applied to all K8s Kops Worker nodes
  node_cloud_labels = {}

  # K8s Kops Master Nodes Machine (EC2) type and size + ASG Min-Max per AZ
  # then min/max = 1 will create 1 Master Node x AZ => 3 x Masters
  kops_master_machine_type     = "t3.medium"
  kops_master_machine_max_size = 1
  kops_master_machine_min_size = 1

  # K8s Kops Worker Nodes Machine (EC2) type and size + ASG Min-Max
  kops_worker_machine_type     = "t3.medium"
  kops_worker_machine_max_size = 5
  kops_worker_machine_min_size = 1
  # If you use Karpenter set the list of types here
  kops_worker_machine_types_karpenter = ["t2.medium", "t2.large", "t3.medium", "t3.large", "t3a.medium", "t3a.large", "m4.large"]

  # master nodes AZs
  # number_of_cluster_master_azs is 1, 2 or 3
  # master nodes will be deployed in these AZs
  number_of_cluster_master_azs = 1
  cluster_master_azs           = slice(data.terraform_remote_state.vpc.outputs.availability_zones, 0, local.number_of_cluster_master_azs )
}
