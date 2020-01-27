locals = {
  cluster_name                 = "cluster-kops-1.k8s.dev.binbash.aws"
  master_autoscaling_group_ids = ["${aws_autoscaling_group.master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws.id}", "${aws_autoscaling_group.master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws.id}", "${aws_autoscaling_group.master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  master_security_group_ids    = ["${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  masters_role_arn             = "${aws_iam_role.masters-cluster-kops-1-k8s-dev-binbash-aws.arn}"

  masters_role_name            = "${aws_iam_role.masters-cluster-kops-1-k8s-dev-binbash-aws.name}"

  node_autoscaling_group_ids   = ["${aws_autoscaling_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  node_security_group_ids      = ["${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  node_subnet_ids              = ["subnet-05d75d908f61d35e5", "subnet-094c287defbc07180", "subnet-0cec521de70ee76a3"]
  nodes_role_arn               = "${aws_iam_role.nodes-cluster-kops-1-k8s-dev-binbash-aws.arn}"

  nodes_role_name              = "${aws_iam_role.nodes-cluster-kops-1-k8s-dev-binbash-aws.name}"

  region                       = "us-east-1"
  subnet_ids                   = ["subnet-00a445cc509021b3f", "subnet-026fdb745614bf70d", "subnet-05d75d908f61d35e5", "subnet-094c287defbc07180", "subnet-0cec521de70ee76a3", "subnet-0f3d2fa193f469407"]
  subnet_us-east-1a_id         = "subnet-05d75d908f61d35e5"
  subnet_us-east-1b_id         = "subnet-094c287defbc07180"
  subnet_us-east-1c_id         = "subnet-0cec521de70ee76a3"
  subnet_utility-us-east-1a_id = "subnet-0f3d2fa193f469407"
  subnet_utility-us-east-1b_id = "subnet-026fdb745614bf70d"
  subnet_utility-us-east-1c_id = "subnet-00a445cc509021b3f"
  vpc_id                       = "vpc-072f329fed6757e95"
}


output "cluster_name" {
  value = "cluster-kops-1.k8s.dev.binbash.aws"
}


output "master_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws.id}", "${aws_autoscaling_group.master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws.id}", "${aws_autoscaling_group.master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

}


output "master_security_group_ids" {
  value = ["${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

}


output "masters_role_arn" {
  value = "${aws_iam_role.masters-cluster-kops-1-k8s-dev-binbash-aws.arn}"

}


output "masters_role_name" {
  value = "${aws_iam_role.masters-cluster-kops-1-k8s-dev-binbash-aws.name}"

}


output "node_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"]

}


output "node_security_group_ids" {
  value = ["${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"]

}


output "node_subnet_ids" {
  value = ["subnet-05d75d908f61d35e5", "subnet-094c287defbc07180", "subnet-0cec521de70ee76a3"]
}


output "nodes_role_arn" {
  value = "${aws_iam_role.nodes-cluster-kops-1-k8s-dev-binbash-aws.arn}"

}


output "nodes_role_name" {
  value = "${aws_iam_role.nodes-cluster-kops-1-k8s-dev-binbash-aws.name}"

}


output "region" {
  value = "us-east-1"
}


output "subnet_ids" {
  value = ["subnet-00a445cc509021b3f", "subnet-026fdb745614bf70d", "subnet-05d75d908f61d35e5", "subnet-094c287defbc07180", "subnet-0cec521de70ee76a3", "subnet-0f3d2fa193f469407"]
}


output "subnet_us-east-1a_id" {
  value = "subnet-05d75d908f61d35e5"
}


output "subnet_us-east-1b_id" {
  value = "subnet-094c287defbc07180"
}


output "subnet_us-east-1c_id" {
  value = "subnet-0cec521de70ee76a3"
}


output "subnet_utility-us-east-1a_id" {
  value = "subnet-0f3d2fa193f469407"
}


output "subnet_utility-us-east-1b_id" {
  value = "subnet-026fdb745614bf70d"
}


output "subnet_utility-us-east-1c_id" {
  value = "subnet-00a445cc509021b3f"
}


output "vpc_id" {
  value = "vpc-072f329fed6757e95"
}




resource "aws_autoscaling_attachment" "master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  elb                    = "${aws_elb.api-cluster-kops-1-k8s-dev-binbash-aws.id}"

  autoscaling_group_name = "${aws_autoscaling_group.master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

}


resource "aws_autoscaling_attachment" "master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  elb                    = "${aws_elb.api-cluster-kops-1-k8s-dev-binbash-aws.id}"

  autoscaling_group_name = "${aws_autoscaling_group.master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

}


resource "aws_autoscaling_attachment" "master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  elb                    = "${aws_elb.api-cluster-kops-1-k8s-dev-binbash-aws.id}"

  autoscaling_group_name = "${aws_autoscaling_group.master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

}


resource "aws_autoscaling_group" "master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name                 = "master-us-east-1a.masters.cluster-kops-1.k8s.dev.binbash.aws"
  launch_configuration = "${aws_launch_configuration.master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-05d75d908f61d35e5"]

  tag = {
    key                 = "Backup"
    value               = "True"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }


  tag = {
    key                 = "KubernetesCluster"
    value               = "cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Name"
    value               = "master-us-east-1a.masters.cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Provisioner"
    value               = "kops"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Service"
    value               = "kubernetes"
    propagate_at_launch = true
  }


  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }


  tag = {
    key                 = "kops.k8s.io/instancegroup"
    value               = "master-us-east-1a"
    propagate_at_launch = true
  }


  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}


resource "aws_autoscaling_group" "master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name                 = "master-us-east-1b.masters.cluster-kops-1.k8s.dev.binbash.aws"
  launch_configuration = "${aws_launch_configuration.master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-094c287defbc07180"]

  tag = {
    key                 = "Backup"
    value               = "True"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }


  tag = {
    key                 = "KubernetesCluster"
    value               = "cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Name"
    value               = "master-us-east-1b.masters.cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Provisioner"
    value               = "kops"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Service"
    value               = "kubernetes"
    propagate_at_launch = true
  }


  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }


  tag = {
    key                 = "kops.k8s.io/instancegroup"
    value               = "master-us-east-1b"
    propagate_at_launch = true
  }


  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}


resource "aws_autoscaling_group" "master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name                 = "master-us-east-1c.masters.cluster-kops-1.k8s.dev.binbash.aws"
  launch_configuration = "${aws_launch_configuration.master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-0cec521de70ee76a3"]

  tag = {
    key                 = "Backup"
    value               = "True"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }


  tag = {
    key                 = "KubernetesCluster"
    value               = "cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Name"
    value               = "master-us-east-1c.masters.cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Provisioner"
    value               = "kops"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Service"
    value               = "kubernetes"
    propagate_at_launch = true
  }


  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }


  tag = {
    key                 = "kops.k8s.io/instancegroup"
    value               = "master-us-east-1c"
    propagate_at_launch = true
  }


  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}


resource "aws_autoscaling_group" "nodes-cluster-kops-1-k8s-dev-binbash-aws" {
  name                 = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
  launch_configuration = "${aws_launch_configuration.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  max_size             = 5
  min_size             = 2
  vpc_zone_identifier  = ["subnet-05d75d908f61d35e5", "subnet-094c287defbc07180", "subnet-0cec521de70ee76a3"]

  tag = {
    key                 = "Backup"
    value               = "True"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }


  tag = {
    key                 = "KubernetesCluster"
    value               = "cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Name"
    value               = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Provisioner"
    value               = "kops"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Service"
    value               = "kubernetes"
    propagate_at_launch = true
  }


  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }


  tag = {
    key                 = "kops.k8s.io/instancegroup"
    value               = "nodes"
    propagate_at_launch = true
  }


  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}


resource "aws_ebs_volume" "a-etcd-events-cluster-kops-1-k8s-dev-binbash-aws" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "a.etcd-events.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "k8s.io/etcd/events"                                       = "a/a,b,c"
    "k8s.io/role/master"                                       = "1"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_ebs_volume" "a-etcd-main-cluster-kops-1-k8s-dev-binbash-aws" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "a.etcd-main.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "k8s.io/etcd/main"                                         = "a/a,b,c"
    "k8s.io/role/master"                                       = "1"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_ebs_volume" "b-etcd-events-cluster-kops-1-k8s-dev-binbash-aws" {
  availability_zone = "us-east-1b"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "b.etcd-events.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "k8s.io/etcd/events"                                       = "b/a,b,c"
    "k8s.io/role/master"                                       = "1"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_ebs_volume" "b-etcd-main-cluster-kops-1-k8s-dev-binbash-aws" {
  availability_zone = "us-east-1b"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "b.etcd-main.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "k8s.io/etcd/main"                                         = "b/a,b,c"
    "k8s.io/role/master"                                       = "1"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_ebs_volume" "c-etcd-events-cluster-kops-1-k8s-dev-binbash-aws" {
  availability_zone = "us-east-1c"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "c.etcd-events.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "k8s.io/etcd/events"                                       = "c/a,b,c"
    "k8s.io/role/master"                                       = "1"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_ebs_volume" "c-etcd-main-cluster-kops-1-k8s-dev-binbash-aws" {
  availability_zone = "us-east-1c"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "c.etcd-main.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "k8s.io/etcd/main"                                         = "c/a,b,c"
    "k8s.io/role/master"                                       = "1"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_elb" "api-cluster-kops-1-k8s-dev-binbash-aws" {
  name = "api-cluster-kops-1-k8s-de-8q8mi4"

  listener = {
    instance_port     = 443
    instance_protocol = "TCP"
    lb_port           = 443
    lb_protocol       = "TCP"
  }


  security_groups = ["${aws_security_group.api-elb-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  subnets         = ["subnet-05d75d908f61d35e5", "subnet-094c287defbc07180", "subnet-0cec521de70ee76a3"]
  internal        = true

  health_check = {
    target              = "SSL:443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }


  cross_zone_load_balancing = false
  idle_timeout              = 300

  tags = {
    Backup                                                     = "True"
    Environment                                                = "dev"
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "api.cluster-kops-1.k8s.dev.binbash.aws"
    Provisioner                                                = "kops"
    Service                                                    = "kubernetes"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_iam_instance_profile" "masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name = "masters.cluster-kops-1.k8s.dev.binbash.aws"
  role = "${aws_iam_role.masters-cluster-kops-1-k8s-dev-binbash-aws.name}"

}


resource "aws_iam_instance_profile" "nodes-cluster-kops-1-k8s-dev-binbash-aws" {
  name = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
  role = "${aws_iam_role.nodes-cluster-kops-1-k8s-dev-binbash-aws.name}"

}


resource "aws_iam_role" "masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name               = "masters.cluster-kops-1.k8s.dev.binbash.aws"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_masters.cluster-kops-1.k8s.dev.binbash.aws_policy")}"

}


resource "aws_iam_role" "nodes-cluster-kops-1-k8s-dev-binbash-aws" {
  name               = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_nodes.cluster-kops-1.k8s.dev.binbash.aws_policy")}"

}


resource "aws_iam_role_policy" "masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name   = "masters.cluster-kops-1.k8s.dev.binbash.aws"
  role   = "${aws_iam_role.masters-cluster-kops-1-k8s-dev-binbash-aws.name}"

  policy = "${file("${path.module}/data/aws_iam_role_policy_masters.cluster-kops-1.k8s.dev.binbash.aws_policy")}"

}


resource "aws_iam_role_policy" "nodes-cluster-kops-1-k8s-dev-binbash-aws" {
  name   = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
  role   = "${aws_iam_role.nodes-cluster-kops-1-k8s-dev-binbash-aws.name}"

  policy = "${file("${path.module}/data/aws_iam_role_policy_nodes.cluster-kops-1.k8s.dev.binbash.aws_policy")}"

}


resource "aws_key_pair" "kubernetes-cluster-kops-1-k8s-dev-binbash-aws-2ccdff0c48dd81bbd2ca91692b8b1c44" {
  key_name   = "kubernetes.cluster-kops-1.k8s.dev.binbash.aws-2c:cd:ff:0c:48:dd:81:bb:d2:ca:91:69:2b:8b:1c:44"
  public_key = "${file("${path.module}/data/aws_key_pair_kubernetes.cluster-kops-1.k8s.dev.binbash.aws-2ccdff0c48dd81bbd2ca91692b8b1c44_public_key")}"

}


resource "aws_launch_configuration" "master-us-east-1a-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name_prefix                 = "master-us-east-1a.masters.cluster-kops-1.k8s.dev.binbash.aws-"
  image_id                    = "ami-069525f6cc64fdff0"
  instance_type               = "t2.large"
  key_name                    = "${aws_key_pair.kubernetes-cluster-kops-1-k8s-dev-binbash-aws-2ccdff0c48dd81bbd2ca91692b8b1c44.id}"

  iam_instance_profile        = "${aws_iam_instance_profile.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  security_groups             = ["${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-east-1a.masters.cluster-kops-1.k8s.dev.binbash.aws_user_data")}"


  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 64
    delete_on_termination = true
  }


  lifecycle = {
    create_before_destroy = true
  }


  enable_monitoring = false
}


resource "aws_launch_configuration" "master-us-east-1b-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name_prefix                 = "master-us-east-1b.masters.cluster-kops-1.k8s.dev.binbash.aws-"
  image_id                    = "ami-069525f6cc64fdff0"
  instance_type               = "t2.large"
  key_name                    = "${aws_key_pair.kubernetes-cluster-kops-1-k8s-dev-binbash-aws-2ccdff0c48dd81bbd2ca91692b8b1c44.id}"

  iam_instance_profile        = "${aws_iam_instance_profile.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  security_groups             = ["${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-east-1b.masters.cluster-kops-1.k8s.dev.binbash.aws_user_data")}"


  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 64
    delete_on_termination = true
  }


  lifecycle = {
    create_before_destroy = true
  }


  enable_monitoring = false
}


resource "aws_launch_configuration" "master-us-east-1c-masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name_prefix                 = "master-us-east-1c.masters.cluster-kops-1.k8s.dev.binbash.aws-"
  image_id                    = "ami-069525f6cc64fdff0"
  instance_type               = "t2.large"
  key_name                    = "${aws_key_pair.kubernetes-cluster-kops-1-k8s-dev-binbash-aws-2ccdff0c48dd81bbd2ca91692b8b1c44.id}"

  iam_instance_profile        = "${aws_iam_instance_profile.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  security_groups             = ["${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-east-1c.masters.cluster-kops-1.k8s.dev.binbash.aws_user_data")}"


  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 64
    delete_on_termination = true
  }


  lifecycle = {
    create_before_destroy = true
  }


  enable_monitoring = false
}


resource "aws_launch_configuration" "nodes-cluster-kops-1-k8s-dev-binbash-aws" {
  name_prefix                 = "nodes.cluster-kops-1.k8s.dev.binbash.aws-"
  image_id                    = "ami-069525f6cc64fdff0"
  instance_type               = "t2.medium"
  key_name                    = "${aws_key_pair.kubernetes-cluster-kops-1-k8s-dev-binbash-aws-2ccdff0c48dd81bbd2ca91692b8b1c44.id}"

  iam_instance_profile        = "${aws_iam_instance_profile.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  security_groups             = ["${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_nodes.cluster-kops-1.k8s.dev.binbash.aws_user_data")}"


  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }


  lifecycle = {
    create_before_destroy = true
  }


  enable_monitoring = false
}


resource "aws_route53_record" "api-cluster-kops-1-k8s-dev-binbash-aws" {
  name = "api.cluster-kops-1.k8s.dev.binbash.aws"
  type = "A"

  alias = {
    name                   = "${aws_elb.api-cluster-kops-1-k8s-dev-binbash-aws.dns_name}"

    zone_id                = "${aws_elb.api-cluster-kops-1-k8s-dev-binbash-aws.zone_id}"

    evaluate_target_health = false
  }


  zone_id = "/hostedzone/Z02860073TM97JGVRH4T4"
}


resource "aws_security_group" "api-elb-cluster-kops-1-k8s-dev-binbash-aws" {
  name        = "api-elb.cluster-kops-1.k8s.dev.binbash.aws"
  vpc_id      = "vpc-072f329fed6757e95"
  description = "Security group for api ELB"

  tags = {
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "api-elb.cluster-kops-1.k8s.dev.binbash.aws"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_security_group" "masters-cluster-kops-1-k8s-dev-binbash-aws" {
  name        = "masters.cluster-kops-1.k8s.dev.binbash.aws"
  vpc_id      = "vpc-072f329fed6757e95"
  description = "Security group for masters"

  tags = {
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "masters.cluster-kops-1.k8s.dev.binbash.aws"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_security_group" "nodes-cluster-kops-1-k8s-dev-binbash-aws" {
  name        = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
  vpc_id      = "vpc-072f329fed6757e95"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster                                          = "cluster-kops-1.k8s.dev.binbash.aws"
    Name                                                       = "nodes.cluster-kops-1.k8s.dev.binbash.aws"
    "kubernetes.io/cluster/cluster-kops-1.k8s.dev.binbash.aws" = "owned"
  }

}


resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}


resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}


resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}


resource "aws_security_group_rule" "api-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.api-elb-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "https-api-elb-172-18-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["172.18.0.0/20"]
}


resource "aws_security_group_rule" "https-elb-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.api-elb-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "icmp-pmtu-api-elb-172-18-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 3
  to_port           = 4
  protocol          = "icmp"
  cidr_blocks       = ["172.18.0.0/20"]
}


resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "node-to-master-protocol-ipip" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 0
  to_port                  = 65535
  protocol                 = "4"
}


resource "aws_security_group_rule" "node-to-master-tcp-1-2379" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 1
  to_port                  = 2379
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "node-to-master-tcp-2382-4001" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 2382
  to_port                  = 4001
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "node-to-master-tcp-4003-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 4003
  to_port                  = 65535
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "node-to-master-udp-1-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port                = 1
  to_port                  = 65535
  protocol                 = "udp"
}


resource "aws_security_group_rule" "ssh-external-to-master-172-18-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.masters-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["172.18.0.0/20"]
}


resource "aws_security_group_rule" "ssh-external-to-node-172-18-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.nodes-cluster-kops-1-k8s-dev-binbash-aws.id}"

  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["172.18.0.0/20"]
}


terraform = {
  required_version = ">= 0.9.3"
}

