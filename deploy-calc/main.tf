provider "aws" {
    region     = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

data "aws_security_group" "tema20-calc" {
    filter {
        name = "group-name"
        values = ["asg-tema20-calc"]
    }
}

data "aws_ami" "tema20-calc" {
    owners = ["self"]
    filter {
        name   = "name"
        values = ["calculator-go"]
    }
}

data "aws_instance" "tema20-redis-master" {
    filter {
        name   = "tag:Name"
        values = ["tema20-redis-master"]
    }
}

data "aws_instance" "tema20-redis-slave" {
    filter {
        name   = "tag:Name"
        values = ["tema20-redis-slave"]
    }
}

data "aws_vpc" "tema20-calc" {
    filter {
        name   = "tag:Name"
        values = ["vpc-tema20"]
    }
}

data "aws_subnet" "tema20-subnet" {
  filter {
    name   = "tag:Name"
    values = ["tema20-a"]
  }
}

resource "aws_launch_configuration" "tema20-calc" {
    image_id        = "${data.aws_ami.tema20-calc.id}"
    name            = "lc-tema20-calc"
    instance_type   = "t2.micro"
    key_name        = "tema20-calc"
    security_groups = ["${data.aws_security_group.tema20-calc.id}"]
    associate_public_ip_address = true
    user_data = <<-EOF
		#!/bin/bash

        export GOPATH=/home/ec2-user/go
        export GOCACHE=/home/ec2-user
        /usr/local/go/bin/go run /home/ec2-user/provisioner/calculator.go "${var.LOGSTASH_URL}" ${data.aws_instance.tema20-redis-master.private_ip} "${data.aws_instance.tema20-redis-slave.private_ip}" "${var.REDIS_MASTER_PASSWORD}" "${var.REDIS_SLAVE_PASSWORD}"
	EOF
}

resource "aws_autoscaling_group" "tema20-calc" {
    name                 = "ag-tema20-calc"
    launch_configuration = "${aws_launch_configuration.tema20-calc.name}"
    min_size             = 2
    max_size             = 4
    load_balancers       = ["${aws_elb.tema20-calc.id}"]
    tag {
        key                 = "Name"
        value               = "tema20-calc"
        propagate_at_launch = true
    }
    vpc_zone_identifier = [
        "${data.aws_subnet.tema20-subnet.id}"
    ]
}

resource "aws_elb" "tema20-calc" {
    name               = "elb-tema20-calc"
    listener {
        instance_port     = 5000
        instance_protocol = "http"
        lb_port           = 5000
        lb_protocol       = "http"
    }
    subnets = ["${data.aws_subnet.tema20-subnet.id}"]
    source_security_group = "${data.aws_security_group.tema20-calc.id}"
    tags = {
        Name = "elb-tema20-calc"
    }
}

resource "aws_autoscaling_attachment" "tema20-calc-aa" {
    autoscaling_group_name = "${aws_autoscaling_group.tema20-calc.id}"
    elb                    = "${aws_elb.tema20-calc.id}"
}
