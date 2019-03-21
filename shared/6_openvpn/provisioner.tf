/*resource "null_resource" "ec2-ansible-wait-until-connection" {
  provisioner "remote-exec" {
    inline = [
//      "echo ${module.ec2_openvpn.public_ip}", # wait for module output in oder to force secuentially exec
      "sudo apt-get install -y python2.7 python-dev python-pip python-setuptools python-virtualenv libssl-dev vim zip"
    ]

    connection {
      type = "ssh"
      user = "${var.provisioner_user}"
      private_key = "${file(var.provisioner_private_key_path)}"
      timeout  = "2m"
      agent = false
    }
  }
}*/

resource "null_resource" "ec2-ansible-playbook" {
  provisioner "local-exec" {
    working_dir = "${var.provisioner_script_path}"
    interpreter = ["/bin/bash"]
    environment {
      OS_USER = "${var.provisioner_user}"
      IP_ADDR = "${module.ec2_openvpn.public_ip}" # wait for module output in oder to force secuentially exec
      SSH_KEY = "${var.provisioner_private_key_relative_script_path}"
    }
    command = "ansible-playbook -u $OS_USER -i '$IP_ADDR,' --private-key $SSH_KEY --extra-vars 'variable_host=$IP_ADDR' setup.yml"
  }
}
