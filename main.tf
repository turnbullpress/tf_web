data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

resource "aws_instance" "web" {
  ami           = "${lookup(var.ami, var.region)}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${element(var.public_subnet_ids, 0)}"
  user_data     = "${file("${path.module}/files/web_bootstrap.sh")}"

  vpc_security_group_ids = [
    "${aws_security_group.web_host_sg.id}",
  ]

  tags {
    Name = "${var.environment}-web-${count.index}"
  }

  count = 2
}

resource "aws_elb" "web" {
  name            = "${var.environment}-web-elb"
  subnets         = ["${element(var.public_subnet_ids, 0)}"]
  security_groups = ["${aws_security_group.web_inbound_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances = ["${aws_instance.web.*.id}"]
}

resource "cloudflare_record" "web" {
    domain = "${var.domain}"
    name = "${var.environment}.${var.domain}"
    value = "${aws_elb.web.dns_name}"
    type = "CNAME"
    ttl = 3600
}

resource "aws_instance" "app" {
  ami           = "${lookup(var.ami, var.region)}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${element(var.private_subnet_ids, 0)}"
  user_data     = "${file("${path.module}/files/app_bootstrap.sh")}"

  vpc_security_group_ids = [
    "${aws_security_group.app_host_sg.id}",
  ]

  tags {
    Name = "${var.environment}-app-${count.index}"
  }

  count = 2
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "${var.environment}-web-inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${data.aws_vpc.environment.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-web-inbound-sg"
  }
}

resource "aws_security_group" "web_host_sg" {
  name        = "${var.environment}-web-host"
  description = "Allow SSH and HTTP to web hosts"
  vpc_id      = "${data.aws_vpc.environment.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-web-host-sg"
  }
}

resource "aws_security_group" "app_host_sg" {
  name        = "${var.environment}-app-host"
  description = "Allow App traffic to app hosts"
  vpc_id      = "${data.aws_vpc.environment.id}"

  # App access from the VPC
  ingress {
    from_port   = 1234
    to_port     = 1234
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-app-host-sg"
  }
}
