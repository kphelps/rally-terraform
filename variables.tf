variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {}

variable "load_driver_node_count" {
  default = 1
}

variable "load_driver_instance_type" {
  default = "t2.micro"
}

variable "elasticsearch_node_count" {
  default = 1
}

variable "elasticsearch_instance_type" {
  default = "t2.micro"
}

variable "metrics_node_count" {
  default = 1
}

variable "metrics_instance_type" {
  default = "t2.small"
}

variable "kibana_node_count" {
  default = 1
}

variable "kibana_instance_type" {
  default = "t2.micro"
}

variable "coordinator_instance_type" {
  default = "t2.micro"
}

variable "amis" {
  type = "map"
  default = {
    "us-east-2" = "ami-5e8bb23b"
  }
}
