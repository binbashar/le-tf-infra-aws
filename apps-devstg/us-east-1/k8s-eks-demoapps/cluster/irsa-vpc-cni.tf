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
# reference on a fresh cluster — the way that was worked around before was to
# install the CNI from the `addons` layer, which runs after `identities`, and to
# let the node instance role carry `AmazonEKS_CNI_Policy` in the meantime. v21
# closed that route: the CNI now has to come up with the cluster.
#
# Keeping the role in this layer gives `aws-node` its own scoped credentials
# from the very first second the cluster exists, and lets the node instance role
# drop `AmazonEKS_CNI_Policy` entirely (see `iam_role_attach_cni_policy` in
# `locals.tf`).
#
# WHAT IS AND IS NOT ORDERED. There is a real dependency chain from the cluster
# to the add-on, because each link passes a value to the next:
#
#   cluster -> OIDC provider -> this role -> vpc-cni add-on
#
# There is **no** edge from the add-on to the node groups. `before_compute` does
# not create one: the module gives the node groups
# `cluster_name = time_sleep.this[0].triggers["name"]`, and that `time_sleep`
# triggers on the *cluster's* attributes only — nothing in it references
# `aws_eks_addon.before_compute`, and `node_groups.tf` contains no `depends_on`
# at all. `before_compute` is a **timed gap**, `var.dataplane_wait_duration`,
# and upstream says so in the comment above that resource. The two branches race
# from the cluster; it works because creating an add-on is short against a
# multi-minute node-group create. See `dataplane_wait_duration` in
# `eks-workers-managed.tf` for why that margin is widened here.
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

  # `local.tags` in this layer is not the same set as in `identities`, where the
  # other eleven IRSA roles live: it carries `Project` but not `Purpose`,
  # `Cluster` or `Subject`. Restored here so this role stays greppable and
  # cost-attributable alongside its siblings rather than becoming the odd one
  # out for having moved layers.
  #
  # The role NAME does diverge from the `${environment}-${prefix}-*` shape those
  # siblings use, and that is deliberate: it is built from the real cluster name,
  # which is the thing this role is actually scoped to, and the `${prefix}`
  # convention belongs to the layer it no longer lives in.
  tags = merge(local.tags, {
    Purpose = "eks-oidc"
    Cluster = data.terraform_remote_state.cluster-vpc.outputs.cluster_name
    Subject = "vpc-cni"
  })
}
