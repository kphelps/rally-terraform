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

resource "aws_lb" "rally_kibana" {
  name = "rally-kibana"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.rally_kibana_lb.id}"]
  subnets = ["${data.aws_subnet_ids.azs.ids}"]
}

resource "aws_lb_target_group" "rally_kibana_target" {
  name = "rally-kibana"
  port = "5601"
  protocol = "HTTP"
  vpc_id = "${var.vpc_id}"
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = "5601"
  }
}

resource "aws_lb_listener" "rally_kibana_listener" {
  load_balancer_arn = "${aws_lb.rally_kibana.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.rally_kibana_target.arn}"
    type             = "forward"
  }
}

resource "aws_autoscaling_group" "rally_kibana_nodes" {
  name_prefix = "${aws_launch_template.rally_kibana_node.name}--"
  max_size = "${var.kibana_node_count}"
  min_size = "${var.kibana_node_count}"
  desired_capacity = "${var.kibana_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  target_group_arns = ["${aws_lb_target_group.rally_kibana_target.arn}"]
  launch_template = {
    id = "${aws_launch_template.rally_kibana_node.id}"
    version = "${aws_launch_template.rally_kibana_node.latest_version}"
  }
}

data "template_file" "rally_kibana_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-kibana"
    elasticsearch_host = "${aws_lb.rally_metrics.dns_name}"
  }
}

resource "aws_launch_template" "rally_kibana_node" {
  name_prefix = "rally-kibana"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.kibana_instance_type}"
  user_data = "${base64encode(data.template_file.rally_kibana_init.rendered)}"
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
