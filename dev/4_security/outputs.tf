# aws_key_pair name
output "aws_key_pair_name" {
  value = "${aws_key_pair.compute-ssh-key.key_name}"
}
