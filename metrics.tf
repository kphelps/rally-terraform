resource "aws_security_group" "rally_metrics_lb" {
  name = "rally-metrics-lb"
  description = "Rally metrics elasticsearch security group"

  ingress {
    from_port = 9200
    to_port = 9200
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

resource "aws_security_group" "rally_metrics" {
  name = "rally-metrics"
  description = "Rally metrics elasticsearch security group"

  ingress {
    from_port = 9200
    to_port = 9200
    protocol = "TCP"
    security_groups = ["${aws_security_group.rally_metrics_lb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "rally_metrics" {
  name = "rally-metrics"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.rally_metrics_lb.id}"]
  subnets = ["${data.aws_subnet_ids.azs.ids}"]
}

resource "aws_lb_target_group" "rally_metrics_target" {
  name = "rally-metrics"
  port = "9200"
  protocol = "HTTP"
  vpc_id = "${var.vpc_id}"
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/_cluster/health"
    port                = "9200"
  }
}

resource "aws_lb_listener" "rally_metrics_listener" {
  load_balancer_arn = "${aws_lb.rally_metrics.arn}"
  port              = "9200"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.rally_metrics_target.arn}"
    type             = "forward"
  }
}

resource "aws_autoscaling_group" "rally_metrics_nodes" {
  name_prefix = "${aws_launch_template.rally_metrics_node.name}--"
  max_size = "${var.metrics_node_count}"
  min_size = "${var.metrics_node_count}"
  desired_capacity = "${var.metrics_node_count}"
  vpc_zone_identifier = ["${data.aws_subnet_ids.azs.ids}"]
  target_group_arns = ["${aws_lb_target_group.rally_metrics_target.arn}"]
  launch_template = {
    id = "${aws_launch_template.rally_metrics_node.id}"
    version = "$$Latest"
  }
}

data "template_file" "rally_metrics_init" {
  template = "${file("salt-init.tpl")}"

  vars {
    hostname = "rally-metrics"
    elasticsearch_host = "localhost"
  }
}

resource "aws_launch_template" "rally_metrics_node" {
  name_prefix = "rally-metrics"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${var.metrics_instance_type}"
  vpc_security_group_ids = [
    "${aws_security_group.rally_nodes.id}"
  ]
  user_data = "${base64encode(data.template_file.rally_metrics_init.rendered)}"
  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "rally-metrics"
    }
  }
}
