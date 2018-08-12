provider "aws" {
  region = "${var.aws_region}"
}

data "aws_subnet_ids" "azs" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "rally_nodes" {
  name = "rally-nodes"
  description = "Rally inter-node communication"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rally_kibana_lb" {
  name = "rally-kibana-lb"
  description = "Kibana security group"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rally_kibana" {
  name = "rally-kibana"
  description = "Kibana security group"

  ingress {
    from_port = 5601
    to_port = 5601
    protocol = "TCP"
    security_groups = ["${aws_security_group.rally_kibana_lb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "rally_elasticsearch_nodes" {
  name = "rally-elasticsearch-nodes"
  max_size = "${var.elasticsearch_node_count}"
  min_size = "${var.elasticsearch_node_count}"
  desired_capacity = "${var.elasticsearch_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  launch_template = {
    id = "${aws_launch_template.rally_elasticsearch_node.id}"
    version = "$$Latest"
  }
}

resource "aws_launch_template" "rally_elasticsearch_node" {
  name_prefix = "rally-elasticsearch-node"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.elasticsearch_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-elasticsearch"
    }
  }
}

resource "aws_autoscaling_group" "rally_load_driver_nodes" {
  name = "rally-load-driver-nodes"
  max_size = "${var.load_driver_node_count}"
  min_size = "${var.load_driver_node_count}"
  desired_capacity = "${var.load_driver_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  launch_template = {
    id = "${aws_launch_template.rally_load_driver_node.id}"
    version = "$$Latest"
  }
}

resource "aws_launch_template" "rally_load_driver_node" {
  name_prefix = "rally-load-driver-node"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.load_driver_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-load-driver"
    }
  }
}

resource "aws_autoscaling_group" "rally_metrics_nodes" {
  name = "rally-metrics-nodes"
  max_size = "${var.metrics_node_count}"
  min_size = "${var.metrics_node_count}"
  desired_capacity = "${var.metrics_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  launch_template = {
    id = "${aws_launch_template.rally_metrics_node.id}"
    version = "$$Latest"
  }
}

resource "aws_launch_template" "rally_metrics_node" {
  name_prefix = "rally-metrics-node"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.metrics_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-metrics"
    }
  }
}

resource "aws_lb" "rally_kibana" {
  name = "rally-kibana"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.rally_kibana_lb.id}"]
  subnets = ["${data.aws_subnet_ids.azs.ids}"]
}

resource "aws_autoscaling_group" "rally_kibana_nodes" {
  name = "rally-kibana-nodes"
  max_size = "${var.kibana_node_count}"
  min_size = "${var.kibana_node_count}"
  desired_capacity = "${var.kibana_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  launch_template = {
    id = "${aws_launch_template.rally_kibana_node.id}"
    version = "$$Latest"
  }
}

resource "aws_launch_template" "rally_kibana_node" {
  name_prefix = "rally-metrics-node"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.metrics_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}",
    "${aws_security_group.rally_kibana.id}"
  ]
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-kibana"
    }
  }
}

resource "aws_instance" "rally_coordinator" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.coordinator_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  tags {
    Name = "rally-coordinator"
  }
  provisioner "remote-exec" {
    inline = [
      "echo ${hostname --ip-address > /etc/rallyd-coordinator-ip}"
    ]
  }
  provisioner "salt-masterless" {
    local_state_tree = "./salt"
  }
}
