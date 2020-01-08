locals = {
  cluster_name                 = "cluster-1.k8s.devstg.binbash.aws"
  master_autoscaling_group_ids = ["${aws_autoscaling_group.master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws.id}"]

  master_security_group_ids    = ["${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"]

  masters_role_arn             = "${aws_iam_role.masters-cluster-1-k8s-devstg-binbash-aws.arn}"

  masters_role_name            = "${aws_iam_role.masters-cluster-1-k8s-devstg-binbash-aws.name}"

  node_autoscaling_group_ids   = ["${aws_autoscaling_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"]

  node_security_group_ids      = ["${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"]

  node_subnet_ids              = ["subnet-01274f4f12fef96f6", "subnet-06300911cc017fc83", "subnet-09594acc20bf04342"]
  nodes_role_arn               = "${aws_iam_role.nodes-cluster-1-k8s-devstg-binbash-aws.arn}"

  nodes_role_name              = "${aws_iam_role.nodes-cluster-1-k8s-devstg-binbash-aws.name}"

  region                       = "us-east-1"
  subnet_ids                   = ["subnet-008393383d35d5efc", "subnet-01274f4f12fef96f6", "subnet-06300911cc017fc83", "subnet-08e61443969c2dd85", "subnet-09594acc20bf04342", "subnet-0c3a67ded37b3d7c8"]
  subnet_us-east-1a_id         = "subnet-09594acc20bf04342"
  subnet_us-east-1b_id         = "subnet-01274f4f12fef96f6"
  subnet_us-east-1c_id         = "subnet-06300911cc017fc83"
  subnet_utility-us-east-1a_id = "subnet-08e61443969c2dd85"
  subnet_utility-us-east-1b_id = "subnet-008393383d35d5efc"
  subnet_utility-us-east-1c_id = "subnet-0c3a67ded37b3d7c8"
  vpc_id                       = "vpc-08eda1f1927b21279"
}


output "cluster_name" {
  value = "cluster-1.k8s.devstg.binbash.aws"
}


output "master_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws.id}"]

}


output "master_security_group_ids" {
  value = ["${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"]

}


output "masters_role_arn" {
  value = "${aws_iam_role.masters-cluster-1-k8s-devstg-binbash-aws.arn}"

}


output "masters_role_name" {
  value = "${aws_iam_role.masters-cluster-1-k8s-devstg-binbash-aws.name}"

}


output "node_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"]

}


output "node_security_group_ids" {
  value = ["${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"]

}


output "node_subnet_ids" {
  value = ["subnet-01274f4f12fef96f6", "subnet-06300911cc017fc83", "subnet-09594acc20bf04342"]
}


output "nodes_role_arn" {
  value = "${aws_iam_role.nodes-cluster-1-k8s-devstg-binbash-aws.arn}"

}


output "nodes_role_name" {
  value = "${aws_iam_role.nodes-cluster-1-k8s-devstg-binbash-aws.name}"

}


output "region" {
  value = "us-east-1"
}


output "subnet_ids" {
  value = ["subnet-008393383d35d5efc", "subnet-01274f4f12fef96f6", "subnet-06300911cc017fc83", "subnet-08e61443969c2dd85", "subnet-09594acc20bf04342", "subnet-0c3a67ded37b3d7c8"]
}


output "subnet_us-east-1a_id" {
  value = "subnet-09594acc20bf04342"
}


output "subnet_us-east-1b_id" {
  value = "subnet-01274f4f12fef96f6"
}


output "subnet_us-east-1c_id" {
  value = "subnet-06300911cc017fc83"
}


output "subnet_utility-us-east-1a_id" {
  value = "subnet-08e61443969c2dd85"
}


output "subnet_utility-us-east-1b_id" {
  value = "subnet-008393383d35d5efc"
}


output "subnet_utility-us-east-1c_id" {
  value = "subnet-0c3a67ded37b3d7c8"
}


output "vpc_id" {
  value = "vpc-08eda1f1927b21279"
}




resource "aws_autoscaling_attachment" "master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws" {
  elb                    = "${aws_elb.api-cluster-1-k8s-devstg-binbash-aws.id}"

  autoscaling_group_name = "${aws_autoscaling_group.master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws.id}"

}


resource "aws_autoscaling_group" "master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws" {
  name                 = "master-us-east-1a.masters.cluster-1.k8s.devstg.binbash.aws"
  launch_configuration = "${aws_launch_configuration.master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws.id}"

  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-09594acc20bf04342"]

  tag = {
    key                 = "Backup"
    value               = "True"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Environment"
    value               = "devstg"
    propagate_at_launch = true
  }


  tag = {
    key                 = "KubernetesCluster"
    value               = "cluster-1.k8s.devstg.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Name"
    value               = "master-us-east-1a.masters.cluster-1.k8s.devstg.binbash.aws"
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


  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}


resource "aws_autoscaling_group" "nodes-cluster-1-k8s-devstg-binbash-aws" {
  name                 = "nodes.cluster-1.k8s.devstg.binbash.aws"
  launch_configuration = "${aws_launch_configuration.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  max_size             = 3
  min_size             = 3
  vpc_zone_identifier  = ["subnet-09594acc20bf04342", "subnet-01274f4f12fef96f6", "subnet-06300911cc017fc83"]

  tag = {
    key                 = "Backup"
    value               = "True"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Environment"
    value               = "devstg"
    propagate_at_launch = true
  }


  tag = {
    key                 = "KubernetesCluster"
    value               = "cluster-1.k8s.devstg.binbash.aws"
    propagate_at_launch = true
  }


  tag = {
    key                 = "Name"
    value               = "nodes.cluster-1.k8s.devstg.binbash.aws"
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


  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}


resource "aws_ebs_volume" "a-etcd-events-cluster-1-k8s-devstg-binbash-aws" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                          = "True"
    Environment                                                     = "devstg"
    KubernetesCluster                                               = "cluster-1.k8s.devstg.binbash.aws"
    Name                                                            = "a.etcd-events.cluster-1.k8s.devstg.binbash.aws"
    Provisioner                                                     = "kops"
    Service                                                         = "kubernetes"
    "k8s.io/etcd/events"                                            = "a/a"
    "k8s.io/role/master"                                            = "1"
    "kubernetes.io/cluster/cluster-1.k8s.devstg.binbash.aws" = "owned"
  }

}


resource "aws_ebs_volume" "a-etcd-main-cluster-1-k8s-devstg-binbash-aws" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Backup                                                          = "True"
    Environment                                                     = "devstg"
    KubernetesCluster                                               = "cluster-1.k8s.devstg.binbash.aws"
    Name                                                            = "a.etcd-main.cluster-1.k8s.devstg.binbash.aws"
    Provisioner                                                     = "kops"
    Service                                                         = "kubernetes"
    "k8s.io/etcd/main"                                              = "a/a"
    "k8s.io/role/master"                                            = "1"
    "kubernetes.io/cluster/cluster-1.k8s.devstg.binbash.aws" = "owned"
  }

}


resource "aws_elb" "api-cluster-1-k8s-devstg-binbash-aws" {
  name = "api-cluster-1-k8s-devstg--t1dao9"

  listener = {
    instance_port     = 443
    instance_protocol = "TCP"
    lb_port           = 443
    lb_protocol       = "TCP"
  }


  security_groups = ["${aws_security_group.api-elb-cluster-1-k8s-devstg-binbash-aws.id}"]

  subnets         = ["subnet-01274f4f12fef96f6", "subnet-06300911cc017fc83", "subnet-09594acc20bf04342"]
  internal        = true

  health_check = {
    target              = "SSL:443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }


  idle_timeout = 300

  tags = {
    Backup                                                          = "True"
    Environment                                                     = "devstg"
    KubernetesCluster                                               = "cluster-1.k8s.devstg.binbash.aws"
    Name                                                            = "api.cluster-1.k8s.devstg.binbash.aws"
    Provisioner                                                     = "kops"
    Service                                                         = "kubernetes"
    "kubernetes.io/cluster/cluster-1.k8s.devstg.binbash.aws" = "owned"
  }

}


resource "aws_iam_instance_profile" "masters-cluster-1-k8s-devstg-binbash-aws" {
  name = "masters.cluster-1.k8s.devstg.binbash.aws"
  role = "${aws_iam_role.masters-cluster-1-k8s-devstg-binbash-aws.name}"

}


resource "aws_iam_instance_profile" "nodes-cluster-1-k8s-devstg-binbash-aws" {
  name = "nodes.cluster-1.k8s.devstg.binbash.aws"
  role = "${aws_iam_role.nodes-cluster-1-k8s-devstg-binbash-aws.name}"

}


resource "aws_iam_role" "masters-cluster-1-k8s-devstg-binbash-aws" {
  name               = "masters.cluster-1.k8s.devstg.binbash.aws"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_masters.cluster-1.k8s.devstg.binbash.aws_policy")}"

}


resource "aws_iam_role" "nodes-cluster-1-k8s-devstg-binbash-aws" {
  name               = "nodes.cluster-1.k8s.devstg.binbash.aws"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_nodes.cluster-1.k8s.devstg.binbash.aws_policy")}"

}


resource "aws_iam_role_policy" "masters-cluster-1-k8s-devstg-binbash-aws" {
  name   = "masters.cluster-1.k8s.devstg.binbash.aws"
  role   = "${aws_iam_role.masters-cluster-1-k8s-devstg-binbash-aws.name}"

  policy = "${file("${path.module}/data/aws_iam_role_policy_masters.cluster-1.k8s.devstg.binbash.aws_policy")}"

}


resource "aws_iam_role_policy" "nodes-cluster-1-k8s-devstg-binbash-aws" {
  name   = "nodes.cluster-1.k8s.devstg.binbash.aws"
  role   = "${aws_iam_role.nodes-cluster-1-k8s-devstg-binbash-aws.name}"

  policy = "${file("${path.module}/data/aws_iam_role_policy_nodes.cluster-1.k8s.devstg.binbash.aws_policy")}"

}


resource "aws_key_pair" "kubernetes-cluster-1-k8s-devstg-binbash-aws-e134d4c7c3b4c867e185681824b3dbbb" {
  key_name   = "kubernetes.cluster-1.k8s.devstg.binbash.aws-e1:34:d4:c7:c3:b4:c8:67:e1:85:68:18:24:b3:db:bb"
  public_key = "${file("${path.module}/data/aws_key_pair_kubernetes.cluster-1.k8s.devstg.binbash.aws-e134d4c7c3b4c867e185681824b3dbbb_public_key")}"

}


resource "aws_launch_configuration" "master-us-east-1a-masters-cluster-1-k8s-devstg-binbash-aws" {
  name_prefix                 = "master-us-east-1a.masters.cluster-1.k8s.devstg.binbash.aws-"
  image_id                    = "ami-06cb76654b9acdcec"
  instance_type               = "m5.large"
  key_name                    = "${aws_key_pair.kubernetes-cluster-1-k8s-devstg-binbash-aws-e134d4c7c3b4c867e185681824b3dbbb.id}"

  iam_instance_profile        = "${aws_iam_instance_profile.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  security_groups             = ["${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-east-1a.masters.cluster-1.k8s.devstg.binbash.aws_user_data")}"


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


resource "aws_launch_configuration" "nodes-cluster-1-k8s-devstg-binbash-aws" {
  name_prefix                 = "nodes.cluster-1.k8s.devstg.binbash.aws-"
  image_id                    = "ami-06cb76654b9acdcec"
  instance_type               = "t2.medium"
  key_name                    = "${aws_key_pair.kubernetes-cluster-1-k8s-devstg-binbash-aws-e134d4c7c3b4c867e185681824b3dbbb.id}"

  iam_instance_profile        = "${aws_iam_instance_profile.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  security_groups             = ["${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_nodes.cluster-1.k8s.devstg.binbash.aws_user_data")}"


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


resource "aws_route53_record" "api-cluster-1-k8s-devstg-binbash-aws" {
  name = "api.cluster-1.k8s.devstg.binbash.aws"
  type = "A"

  alias = {
    name                   = "${aws_elb.api-cluster-1-k8s-devstg-binbash-aws.dns_name}"

    zone_id                = "${aws_elb.api-cluster-1-k8s-devstg-binbash-aws.zone_id}"

    evaluate_target_health = false
  }


  zone_id = "/hostedzone/Z06993763NC5WWC2DQSZK"
}


resource "aws_security_group" "api-elb-cluster-1-k8s-devstg-binbash-aws" {
  name        = "api-elb.cluster-1.k8s.devstg.binbash.aws"
  vpc_id      = "vpc-08eda1f1927b21279"
  description = "Security group for api ELB"

  tags = {
    KubernetesCluster                                               = "cluster-1.k8s.devstg.binbash.aws"
    Name                                                            = "api-elb.cluster-1.k8s.devstg.binbash.aws"
    "kubernetes.io/cluster/cluster-1.k8s.devstg.binbash.aws" = "owned"
  }

}


resource "aws_security_group" "masters-cluster-1-k8s-devstg-binbash-aws" {
  name        = "masters.cluster-1.k8s.devstg.binbash.aws"
  vpc_id      = "vpc-08eda1f1927b21279"
  description = "Security group for masters"

  tags = {
    KubernetesCluster                                               = "cluster-1.k8s.devstg.binbash.aws"
    Name                                                            = "masters.cluster-1.k8s.devstg.binbash.aws"
    "kubernetes.io/cluster/cluster-1.k8s.devstg.binbash.aws" = "owned"
  }

}


resource "aws_security_group" "nodes-cluster-1-k8s-devstg-binbash-aws" {
  name        = "nodes.cluster-1.k8s.devstg.binbash.aws"
  vpc_id      = "vpc-08eda1f1927b21279"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster                                               = "cluster-1.k8s.devstg.binbash.aws"
    Name                                                            = "nodes.cluster-1.k8s.devstg.binbash.aws"
    "kubernetes.io/cluster/cluster-1.k8s.devstg.binbash.aws" = "owned"
  }

}


resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}


resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}


resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}


resource "aws_security_group_rule" "api-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.api-elb-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "https-api-elb-172-17-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["172.17.0.0/20"]
}


resource "aws_security_group_rule" "https-elb-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.api-elb-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "icmp-pmtu-api-elb-172-17-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 3
  to_port           = 4
  protocol          = "icmp"
  cidr_blocks       = ["172.17.0.0/20"]
}


resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "node-to-master-protocol-ipip" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 0
  to_port                  = 65535
  protocol                 = "4"
}


resource "aws_security_group_rule" "node-to-master-tcp-1-2379" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 1
  to_port                  = 2379
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "node-to-master-tcp-2382-4001" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 2382
  to_port                  = 4001
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "node-to-master-tcp-4003-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 4003
  to_port                  = 65535
  protocol                 = "tcp"
}


resource "aws_security_group_rule" "node-to-master-udp-1-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  source_security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port                = 1
  to_port                  = 65535
  protocol                 = "udp"
}


resource "aws_security_group_rule" "ssh-external-to-master-172-17-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.masters-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["172.17.0.0/20"]
}


resource "aws_security_group_rule" "ssh-external-to-node-172-17-0-0--20" {
  type              = "ingress"
  security_group_id = "${aws_security_group.nodes-cluster-1-k8s-devstg-binbash-aws.id}"

  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["172.17.0.0/20"]
}


terraform = {
  required_version = ">= 0.9.3"
}

