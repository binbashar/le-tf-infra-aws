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

resource "template_file" "userdata" {
  template = "${file("userdata.sh")}"
}

resource "aws_instance" "jenkins-vault_instance" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${list(module.sg_private.id)}"]
  subnet_id = "${data.terraform_remote_state.vpc.private_subnets[0]}"
  key_name = "${data.terraform_remote_state.security.aws_key_pair_name}"
  user_data = "${template_file.userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins.id}"

  tags = "${local.tags}"

  lifecycle {
    ignore_changes = ["ami"]
  }
}