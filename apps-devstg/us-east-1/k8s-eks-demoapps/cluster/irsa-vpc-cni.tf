#
# IRSA role for the VPC CNI (`aws-node`)
# ------------------------------------------------------------------------------
# This role lives HERE, in the cluster layer, rather than in `identities` with
# every other IRSA role. That is deliberate, and it is the only way to give the
# CNI its own identity in a single apply.
#
# The CNI has to be installed *before* the nodes (see `local.bootstrap_addons`),
# because a node cannot reach `Ready` without it. `identities` runs *after* the
# cluster. So a CNI role in `identities` is a role the bootstrap add-on can never
# reference on a fresh cluster — that circularity is what the three-step
# `use_managed_addons` dance at the bottom of `locals.tf` was working around, and
# it is why the CNI ran on the node instance role at all.
#
# Keeping it in this layer collapses the whole thing into one dependency chain
# that OpenTofu can order by itself:
#
#   cluster + OIDC provider -> this role -> vpc-cni add-on -> node groups
#
# so `aws-node` has its own scoped credentials from the very first second the
# cluster exists, and the node instance role never needs `AmazonEKS_CNI_Policy`
# (see `iam_role_attach_cni_policy` in `locals.tf`).
#
# NOTE the `provider_url` derivation. IAM rejects a trust policy naming an OIDC
# provider that does not exist yet, and `cluster_oidc_issuer_url` is read off the
# cluster resource, not off the provider — using it would let this role be
# created first and fail with `MalformedPolicyDocument: Invalid principal in
# policy`. Deriving the same URL from the provider's *own ARN* makes the
# dependency real.
module "irsa_vpc_cni" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.24.1"

  create_role = true
  # cluster_name is already `${project}-${environment}-eks-demoapps`, so it
  # carries the prefix -- do not prepend `var.environment` again.
  role_name    = "${data.terraform_remote_state.cluster-vpc.outputs.cluster_name}-vpc-cni"
  provider_url = replace(module.cluster.oidc_provider_arn, "/^.*oidc-provider\\//", "")

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:aws-node"
  ]

  tags = local.tags
}
