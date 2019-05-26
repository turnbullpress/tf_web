variable "region" {
  type = string
  description = "The AWS region."
}

variable "environment" {
  type = string
  description = "The name of our environment, i.e. development."
}

variable "key_name" {
  type = string
  description = "The AWS key pair to use for resources."
}

variable "public_subnet_ids" {
  type = list(string)
  default     = []
  description = "The list of public subnets to populate."
}

variable "private_subnet_ids" {
  type = list(string)
  default     = []
  description = "The list of private subnets to populate."
}

variable "ami" {
  type = map(string)
  default = {
    "us-east-1" = "ami-f652979b"
    "us-west-1" = "ami-7c4b331c"
  }

  description = "The AMIs to use for web and app instances."
}

variable "instance_type" {
  type = string
  default     = "t2.micro"
  description = "The instance type to launch "
}

variable "web_instance_count" {
  type = number
  default     = 1
  description = "The number of Web instances to create"
}

variable "app_instance_count" {
  type = number
  default     = 1
  description = "The number of App instances to create"
}

variable "vpc_id" {
  type = string
  description = "The VPC ID to launch in"
}

variable "domain" {
  type = string
  description = "The domain to use for the web service"
}

output "web_elb_address" {
  value = aws_elb.web.dns_name
}

output "web_host_addresses" {
  value = aws_instance.web[*].private_ip
}

output "app_host_addresses" {
  value = aws_instance.app[*].private_ip
}

