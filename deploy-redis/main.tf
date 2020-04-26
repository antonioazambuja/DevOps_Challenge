provider "aws" {
    region     = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

data "aws_security_group" "tema20-redis" {
    filter {
        name = "group-name"
        values = ["asg-tema20-redis"]
    }
}

data "aws_ami" "tema20-redis" {
    owners = ["self"]
    filter {
        name   = "name"
        values = ["redis"]
    }
}

data "aws_vpc" "tema20-redis" {
    filter {
        name   = "tag:Name"
        values = ["vpc-tema20"]
    }
}

data "aws_subnet" "tema20-redis" {
    filter {
        name   = "tag:Name"
        values = ["tema20-a"]
    }
}

resource "aws_instance" "tema20-redis-master" {
    key_name               = "tema20-redis"
    instance_type          = "t2.micro"
    ami                    = "${data.aws_ami.tema20-redis.id}"
    vpc_security_group_ids = [
        "${data.aws_security_group.tema20-redis.id}"
    ]
    subnet_id = "${data.aws_subnet.tema20-redis.id}"
    associate_public_ip_address = true
    tags = {
        Name = "tema20-redis-master"
    }
    user_data = <<-EOF
		#!/bin/bash

        sysctl vm.overcommit_memory=1
        sed -i "s/# requirepass foobared/requirepass "${var.REDIS_MASTER_PASSWORD}"/" /redis-5.0.7/redis.conf

        systemctl enable redis        
        systemctl start redis

	EOF
}

resource "aws_instance" "tema20-redis-slave" {
    key_name               = "tema20-redis"
    instance_type          = "t2.micro"
    ami                    = "${data.aws_ami.tema20-redis.id}"
    vpc_security_group_ids = [
        "${data.aws_security_group.tema20-redis.id}"
    ]
    subnet_id = "${data.aws_subnet.tema20-redis.id}"
    associate_public_ip_address = true
    tags = {
        Name = "tema20-redis-slave"
    }
    user_data = <<-EOF
		#!/bin/bash

        sysctl vm.overcommit_memory=1
        sed -i "s/# replicaof <masterip> <masterport>/replicaof "${aws_instance.tema20-redis-master.private_ip}" 6379/" /redis-5.0.7/redis.conf
        sed -i "s/# masterauth <master-password>/masterauth "${var.REDIS_MASTER_PASSWORD}"/" /redis-5.0.7/redis.conf
        sed -i "s/# requirepass foobared/requirepass "${var.REDIS_SLAVE_PASSWORD}"/" /redis-5.0.7/redis.conf
        
        systemctl enable redis        
        systemctl start redis

    EOF
}

resource "aws_elb" "tema20-redis" {
    name                  = "elb-tema20-redis"
    instances             = [
        "${aws_instance.tema20-redis-master.id}",
        "${aws_instance.tema20-redis-slave.id}"
    ]
    source_security_group = "${data.aws_security_group.tema20-redis.id}"
    subnets = [
        "${data.aws_subnet.tema20-redis.id}"
    ]
    listener {
        instance_port     = 6379
        instance_protocol = "http"
        lb_port           = 6379
        lb_protocol       = "http"
    }
    security_groups       = ["${data.aws_security_group.tema20-redis.id}"]
}
