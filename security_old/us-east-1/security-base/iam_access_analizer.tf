#
# NOTE: In order to enable AccessAnalyzer with the Organization at the zone of
# of trust in the Security account, this account needs to be set as a delegated
# administrator. Such step cannot be performed by Terraform yet so it was set
# up manually as described below:
# https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-settings.html
#

resource "aws_accessanalyzer_analyzer" "default" {
  analyzer_name = "ConsoleAnalyzer-bc3bc4d6-09cb-43f5-974c-303a7c55ded2"
  type          = "ORGANIZATION"
  tags          = local.tags
}
