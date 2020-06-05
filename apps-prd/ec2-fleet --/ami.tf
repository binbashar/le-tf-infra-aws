data "aws_ami" "ubuntu_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.aws_ami_os_id]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  //https://askubuntu.com/questions/53582/how-do-i-know-what-ubuntu-ami-to-launch-on-ec2
  //  Any user can register an AMI under any name. Nothing prevents a malicious user from registering an AMI that would
  //  match the search above. So, in order to be safe, you need to verify that the owner of the ami is '099720109477'.
  owners = [var.aws_ami_os_owner] # Canonical
}
