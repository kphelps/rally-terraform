data "template_file" "rally_coordinator_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-coordinator"
    elasticsearch_host = "${aws_lb.rally_metrics.dns_name}"
  }
}

resource "aws_instance" "rally_coordinator" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.coordinator_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  user_data = "${base64encode(data.template_file.rally_coordinator_init.rendered)}"
  tags {
    Name = "rally-coordinator"
  }
}
