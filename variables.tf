variable "ssh_key" {
  description = "The SSH Key you want to use to SSH into the instance"
  type        = string
}

variable "aws_region" {
  description = "The aws region you want to create your resources in"
  type        = string
}

variable "web_server_count" {
  description = "The number of webserver you want to create"
  type        = number
}

variable "ami_id" {
  description = "The ami id you want to use for webserver"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR address you want to allocate to VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "The list of public subnet CIDRs you want to use"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "The list of private subnet CIDRs you want to use"
  type        = list(string)
}
