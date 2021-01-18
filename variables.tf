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
