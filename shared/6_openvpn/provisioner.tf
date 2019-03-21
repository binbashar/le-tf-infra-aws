resource "null_resource" "ec2-ansible-wait-until-connection" {
  provisioner "remote-exec" {
    inline = [
      "echo ${module.ec2_openvpn.public_ip}",
      "sudo apt-get update",
      "sudo apt-get install -y python2.7 python-dev python-pip python-setuptools python-virtualenv libssl-dev vim zip"
    ]

    connection {
      host        = "${module.ec2_openvpn.public_ip}" # wait for module output in oder to force secuentially exec
      type        = "ssh"
      port        = 22
      user        = "${var.provisioner_user}"
      private_key = "${file(var.provisioner_private_key_path)}"
      timeout     = "1m"
      agent       = false
    }
  }
}

resource "null_resource" "ec2-ansible-playbook" {
  provisioner "local-exec" {
    command = "cd ${var.provisioner_script_path} && ansible-playbook -u ${var.provisioner_user} -i '${module.ec2_openvpn.public_ip},' --private-key ${var.provisioner_private_key_relative_script_path} --extra-vars 'variable_host=${module.ec2_openvpn.public_ip}' setup.yml"
  }
}
