provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_vpc" "tema20" {
    cidr_block = "172.17.0.0/16"
    tags = {
        Name   = "vpc-tema20"
    }
}

resource "aws_internet_gateway" "tema20" {
    vpc_id = "${aws_vpc.tema20.id}"
    tags = {
        Name = "ig-tema20"
    }
}

resource "aws_route_table" "tema20" {
    vpc_id = "${aws_vpc.tema20.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tema20.id}"
    }

    route {
        ipv6_cidr_block        = "::/0"
        egress_only_gateway_id = "${aws_egress_only_internet_gateway.tema20.id}"
    }

    tags = {
        Name = "rt-tema20"
    }
}

resource "aws_main_route_table_association" "tema20" {
    vpc_id         = "${aws_vpc.tema20.id}"
    route_table_id = "${aws_route_table.tema20.id}"
}

resource "aws_egress_only_internet_gateway" "tema20" {
    vpc_id = "${aws_vpc.tema20.id}"
}

resource "aws_subnet" "tema20-a" {
    availability_zone = "us-east-2a"
    cidr_block        = "172.17.0.0/20"
    vpc_id            = "${aws_vpc.tema20.id}"
    tags = {
        Name = "tema20-a"
    }
}

resource "aws_subnet" "tema20-b" {
    availability_zone = "us-east-2b"
    cidr_block        = "172.17.16.0/20"
    vpc_id            = "${aws_vpc.tema20.id}"
    tags = {
        Name = "tema20-b"
    }
}

resource "aws_subnet" "tema20-c" {
    availability_zone = "us-east-2c"
    cidr_block        = "172.17.32.0/20"
    vpc_id            = "${aws_vpc.tema20.id}"
    tags = {
        Name = "tema20-c"
    }
}

resource "aws_security_group" "tema20-calc" {
  name = "asg-tema20-calc"
  vpc_id = "${aws_vpc.tema20.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.MY_IP}/32"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["${var.MY_IP}/32"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    self = "true"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asg-tema20-calc"
  }
}

resource "aws_security_group" "tema20-redis" {
  name   = "asg-tema20-redis"
  vpc_id = "${aws_vpc.tema20.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.MY_IP}/32"]
  }
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${var.MY_IP}/32"]
  }
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self = "true"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "asg-tema20-redis"
  }
}

resource "aws_security_group_rule" "tema20-redis-ingress-calc" {
    type = "ingress"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_group_id = "${aws_security_group.tema20-redis.id}"
    source_security_group_id = "${aws_security_group.tema20-calc.id}"
}

resource "aws_security_group_rule" "tema20-calc-ingress-redis" {
    type = "ingress"
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    security_group_id = "${aws_security_group.tema20-calc.id}"
    source_security_group_id = "${aws_security_group.tema20-redis.id}"
}
