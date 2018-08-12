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

data "template_file" "rally_kibana_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-kibana"
  }
}

resource "aws_launch_template" "rally_kibana_node" {
  name_prefix = "rally-kibana"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.metrics_instance_type}"
  user_data = "${data.template_file.rally_kibana_init.rendered}"
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
