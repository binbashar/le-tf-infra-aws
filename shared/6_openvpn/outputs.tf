# EC2 EIP
output "public_ip" {
  description = "Contains the public IP address."
  value = "${aws_eip.this.public_ip}"
}
