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

data "template_file" "rally_metrics_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-metrics"
  }
}

resource "aws_launch_template" "rally_metrics_node" {
  name_prefix = "rally-metrics"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.metrics_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  user_data = "${data.template_file.rally_metrics_init.rendered}"
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-metrics"
    }
  }
}
