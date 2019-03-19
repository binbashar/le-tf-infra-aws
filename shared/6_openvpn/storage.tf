//
// AWS EBS
//

# Note: this resource was imported for tagging purposes only.
resource "aws_ebs_volume" "root" {
  availability_zone = "us-east-1a"
  size = 16
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"

  lifecycle {
    prevent_destroy = true
  }
}