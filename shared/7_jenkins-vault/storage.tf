//
// AWS EBS
//

# Note: this resource was imported for tagging purposes only.
resource "aws_ebs_volume" "root" {
  availability_zone = "us-east-1a"
  size = "${var.volume_size_root}"
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_ebs_volume" "jenkins-data" {
  availability_zone = "us-east-1a"
  size = "${var.volume_size_extra_1}"
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"
}

resource "aws_ebs_volume" "docker-data" {
  availability_zone = "us-east-1a"
  size = "${var.volume_size_extra_2}"
  type = "gp2"
  tags = "${merge(local.tags, map("Backup", "True"))}"
}

resource "aws_volume_attachment" "jenkins_ebs_att_1" {
    device_name = "/dev/sdh"
    volume_id = "${aws_ebs_volume.jenkins-data.id}"
    instance_id = "${aws_instance.jenkins-vault_instance.id}"
}
resource "aws_volume_attachment" "jenkins_ebs_att_2" {
    device_name = "/dev/sdi"
    volume_id = "${aws_ebs_volume.docker-data.id}"
    instance_id = "${aws_instance.jenkins-vault_instance.id}"
}

//
// AWS S3
//
resource "aws_s3_bucket" "vault_bucket" {
  bucket        = "bb-shared-vault-storage"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  tags = "${local.tags}"
}