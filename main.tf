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

  ingress {
    from_port = 22
    to_port = 22
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

