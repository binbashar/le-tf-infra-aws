#
# ECR Lifecycle Policy
#
data "aws_ecr_lifecycle_policy_document" "default_lifecycle_policy" {
  rule {
    priority    = 1
    description = "Keep only the last 20 images (no tag filtering)"

    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "imageCountMoreThan"
      count_number     = 20
    }

    action {
      type = "expire"
    }
  }
  rule {
    priority    = 2
    description = "Expire images older than 90 days (no tag filtering)"

    selection {
      tag_status   = "any"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 90
    }

    action {
      type = "expire"
    }
  }
}
