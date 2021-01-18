locals {

  security_group_web_inbound_rules = [{
    "from" : "80"
    "to" : "80"
    "protocol" : "tcp"
    "description" : "HTTP port"
    "security_group" : aws_security_group.web_alb_sg.id
    },
    {
      "from" : "443"
      "to" : "443"
      "protocol" : "tcp"
      "description" : "HTTPS port"
      "security_group" : aws_security_group.web_alb_sg.id
  }]

  security_group_web_alb_inbound_rules = [{
    "from" : "80"
    "to" : "80"
    "protocol" : "tcp"
    "description" : "HTTP port"
    "access_cidr" : "0.0.0.0/0"
    },
    {
      "from" : "443"
      "to" : "443"
      "protocol" : "tcp"
      "description" : "HTTPS port"
      "access_cidr" : "0.0.0.0/0"
  }]

  security_group_outbound_rules = [{
    "from" : "0"
    "to" : "0"
    "protocol" : "-1"
    "description" : "All traffic"
    "access_cidr" : "0.0.0.0/0"
  }]

  tags = {
    common_tags = {
      ManagedBy = "Terraform"
      Project   = "test"
    }
  }
}
