#=============================#
# Compute Optimizer opt-in    #
#=============================#
# Enables rightsizing / idle-resource recommendations for the FinOps Agent. Scoped to
# the management account only; flip include_member_accounts (and enable Organizations
# trusted access) to enroll the whole org later.
resource "aws_computeoptimizer_enrollment_status" "this" {
  count = var.enable_compute_optimizer ? 1 : 0

  status                  = "Active"
  include_member_accounts = false
}
