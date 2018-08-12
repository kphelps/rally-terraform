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
