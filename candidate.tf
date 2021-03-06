resource "aws_autoscaling_group" "rally_elasticsearch_nodes" {
  name_prefix = "${aws_launch_template.rally_elasticsearch_node.name}--"
  max_size = "${var.elasticsearch_node_count}"
  min_size = "${var.elasticsearch_node_count}"
  desired_capacity = "${var.elasticsearch_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  launch_template = {
    id = "${aws_launch_template.rally_elasticsearch_node.id}"
    version = "${aws_launch_template.rally_elasticsearch_node.latest_version}"
  }
}

data "template_file" "rally_elasticsearch_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-elasticsearch"
    coordinator_ip = "${aws_instance.rally_coordinator.private_ip}"
    elasticsearch_host = "${aws_lb.rally_metrics.dns_name}"
  }
}

resource "aws_launch_template" "rally_elasticsearch_node" {
  name_prefix = "rally-elasticsearch"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.elasticsearch_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  user_data = "${base64encode(data.template_file.rally_elasticsearch_init.rendered)}"
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-elasticsearch"
    }
  }
}
