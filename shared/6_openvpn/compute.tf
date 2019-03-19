data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.aws_ami_os_id}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

//https://askubuntu.com/questions/53582/how-do-i-know-what-ubuntu-ami-to-launch-on-ec2
//  Any user can register an AMI under any name. Nothing prevents a malicious user from registering an AMI that would
//  match the search above. So, in order to be safe, you need to verify that the owner of the ami is '099720109477'.
  owners = ["${var.aws_ami_os_owner}"] # Canonical
}

resource "aws_instance" "openvpn_instance" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${list(aws_security_group.allow_ssh.id, aws_security_group.pritunl_temporary_access.id)}"]
  subnet_id = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  key_name = "${data.terraform_remote_state.security.aws_key_pair_name}"

  tags = "${local.tags}"

  lifecycle {
    ignore_changes = ["ami"]
  }
}

resource "aws_eip" "this" {
  instance = "${aws_instance.openvpn_instance.id}"
  vpc      = true
}