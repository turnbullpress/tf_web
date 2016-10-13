variable "region" {}
variable "ami" {
  type    = "map"
  default = {}
}
variable "instance_type" {
  default = "t2.micro"
}
variable "key_name" {
  default = "james"
}
variable "environment" {}
