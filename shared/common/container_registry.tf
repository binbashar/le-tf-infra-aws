#
# ECR Life-cycle Policy: only keep the latest 10 tagged images.
#
module "ecr_lifecycle_rule_tagged_dev_image_count_7" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ecr-tf/ecr-lifecycle-policy-rule?ref=v0.2"

    tag_status   = "tagged"
    count_type   = "imageCountMoreThan"
    prefixes     = ["dev"]
    count_number = 7
}

module "ecr_lifecycle_rule_tagged_stg_image_count_7" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ecr-tf/ecr-lifecycle-policy-rule?ref=v0.2"

    tag_status   = "tagged"
    count_type   = "imageCountMoreThan"
    prefixes     = ["stg"]
    count_number = 7
}

module "ecr_lifecycle_rule_tagged_prd_image_count_7" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ecr-tf/ecr-lifecycle-policy-rule?ref=v0.2"

    tag_status   = "tagged"
    count_type   = "imageCountMoreThan"
    prefixes     = ["prd"]
    count_number = 7
}

module "ecr_lifecycle_rule_tagged_rel_image_count_7" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ecr-tf/ecr-lifecycle-policy-rule?ref=v0.2"

    tag_status   = "tagged"
    count_type   = "imageCountMoreThan"
    prefixes     = ["release"]
    count_number = 7
}

#
# ECR Registry: NativeWeb VINTRO
#
module "nativeweb_leverage_ecr_repo" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ecr-tf/ecr-cross-account?ref=v0.2"

    namespace = "bb"
    name      = "leverage"

    allowed_read_principals = [
        "arn:aws:iam::${var.dev_account_id}:root",
        "arn:aws:iam::${var.appsprd_account_id}:root",
    ]
    allowed_write_principals = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    ]

    lifecycle_policy_rules = [
        "${module.ecr_lifecycle_rule_tagged_dev_image_count_7.policy_rule}",
        "${module.ecr_lifecycle_rule_tagged_stg_image_count_7.policy_rule}",
        "${module.ecr_lifecycle_rule_tagged_prd_image_count_7.policy_rule}"
    ]
    lifecycle_policy_rules_count = 3
}

#
# ECR Registry: DevOps OneTimeSecret
#
module "devops_ots_ecr_repo" {
    source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ecr-tf/ecr-cross-account?ref=v0.2"

    namespace = "devops"
    name      = "ots"

    allowed_read_principals = [
        "arn:aws:iam::${var.dev_account_id}:root",
        "arn:aws:iam::${var.appsprd_account_id}:root",
    ]
    allowed_write_principals = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    ]

    lifecycle_policy_rules = []
    lifecycle_policy_rules_count = 0
}