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

data "template_file" "rally_load_driver_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-load-driver"
    coordinator_ip = "${aws_instance.rally_coordinator.private_ip}"
  }
}

resource "aws_launch_template" "rally_load_driver_node" {
  name_prefix = "rally-load-driver-node"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.load_driver_instance_type}"
  user_data = "${data.template_file.rally_load_driver_init.rendered}"
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
