resource "aws_eip" "this" {
  instance = "${aws_instance.openvpn_instance.id}"
  vpc      = true
}