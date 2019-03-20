resource "null_resource" "ec2-ansible-wait-until-connection" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y python2.7 python-dev python-pip python-setuptools python-virtualenv libssl-dev vim zip"
    ]

    connection {
      type = "ssh"
      user = "${var.provisioner_user}"
      private_key = "${file(var.provisioner_private_key_path)}"
    }
  }
}

resource "null_resource" "ec2-ansible-playbook" {
  provisioner "local-exec" {
    command = "cd ${var.provisioner_script_path} && ansible-playbook -u ${var.provisioner_user} -i '${aws_eip.this.public_ip},' --private-key ${var.provisioner_private_key_relative_script_path} --extra-vars 'variable_host=${aws_eip.this.public_ip}' setup.yml"
  }
}