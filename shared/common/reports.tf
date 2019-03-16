resource "aws_s3_bucket" "reports" {
    bucket    = "scoutsuite-reports"
    acl       = "private"
    region    = "${var.region}"

    versioning {
        enabled = false
    }

    lifecycle_rule {
        enabled = true
        prefix  = "${var.reports_key_prefix}/"

        expiration {
            days = 365
        }
    }

}

