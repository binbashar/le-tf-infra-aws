#
# Activating a user-defined tag as a cost allocation tag is what makes it
# visible in Cost Explorer and the CUR. Applying the tag to resources is not
# enough on its own -- an inactive tag leaves the spend reading as untagged,
# which is exactly how PRM attribution silently fails to be verifiable.
#
# Payer-account only: cost allocation tags are an organization-wide setting
# owned by the management account.
#
resource "aws_ce_cost_allocation_tag" "prm_apn_id" {
  tag_key = "aws-apn-id"
  status  = "Active"
}
