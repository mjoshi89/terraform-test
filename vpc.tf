#Ideally would have used the VPC module
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge({
    Name = "test-vpc"
  }, local.tags.common_tags)
}

#Subnet Creation
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge({
    Name = "public_subnet_${count.index + 1}"
  }, local.tags.common_tags)
}

resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name = "private_subnet_${count.index + 1}"
  }, local.tags.common_tags)
}

#Gateways
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "test-igw"
  }, local.tags.common_tags)
}

resource "aws_eip" "nat" {
  count = max(length(aws_subnet.public_subnet), length(aws_subnet.private_subnet))
  vpc   = true
}

resource "aws_nat_gateway" "nat_gw" {
  count         = max(length(aws_subnet.public_subnet), length(aws_subnet.private_subnet))
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
  depends_on    = [aws_internet_gateway.internet_gateway]
}

#Public Routes

resource "aws_route_table" "public" {
  count  = length(aws_subnet.public_subnet)
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "public-route-table_${count.index + 1}"
  }, local.tags.common_tags)
}

resource "aws_route" "public_route" {
  count                  = length(aws_subnet.public_subnet)
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
  depends_on             = [aws_route_table.public]
}

resource "aws_route_table_association" "public_subnet" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

#Private Routes

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private_subnet)
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "private-route-table_${count.index + 1}"
  }, local.tags.common_tags)
}

resource "aws_route" "private_route" {
  count                  = length(aws_subnet.private_subnet)
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gw.*.id,count.index)
  depends_on             = [aws_route_table.private]
}

resource "aws_route_table_association" "private_subnet" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "web_alb_sg" {
  name        = "web_alb_sg"
  description = "Allow inbound traffic to ALB"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = local.security_group_web_alb_inbound_rules
    iterator = property
    content {
      from_port   = property.value.from
      to_port     = property.value.to
      protocol    = property.value.protocol
      cidr_blocks = [property.value.access_cidr]
      description = property.value.description
    }
  }

  dynamic "egress" {
    for_each = local.security_group_outbound_rules
    iterator = property
    content {
      from_port   = property.value.from
      to_port     = property.value.to
      protocol    = property.value.protocol
      description = property.value.description
      cidr_blocks = [property.value.access_cidr]
    }
  }
}

resource "aws_security_group" "web_instance_sg" {
  name        = "web_instance_sg"
  description = "Allow inbound traffic to instance"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = local.security_group_web_inbound_rules
    iterator = property
    content {
      from_port       = property.value.from
      to_port         = property.value.to
      protocol        = property.value.protocol
      security_groups = [property.value.security_group]
      description     = property.value.description
    }
  }

  dynamic "egress" {
    for_each = local.security_group_outbound_rules
    iterator = property
    content {
      from_port   = property.value.from
      to_port     = property.value.to
      protocol    = property.value.protocol
      description = property.value.description
      cidr_blocks = [property.value.access_cidr]
    }
  }
}

/*
One way is this as descibed below, but let's use asg
resource "aws_instance" "web" {
  count         = var.web_server_count
  ami           = "ami-403e2524"
  instance_type = "t2.micro"
  user_data     = "#!/bin/bash\nyum update -y\nyum install -y httpd24\nservice httpd start"
  subnet_id     = element(aws_subnet.private_subnet.*.id, count.index)
  key_name      = var.ssh_key

  vpc_security_group_ids = [
    aws_security_group.web_instance_sg.id,
  ]

  tags = {
    Name = "web"
  }
}
*/
module "web_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "web"

  # Launch configuration
  lc_name = "web-lc"

  image_id          = var.ami_id
  instance_type     = "t2.micro"
  security_groups   = [aws_security_group.web_instance_sg.id]
  user_data         = "#!/bin/bash\nyum update -y\nyum install -y httpd24\nservice httpd start"
  target_group_arns = module.web-server-alb.target_group_arns

  # Auto scaling group
  asg_name                  = "web-asg"
  vpc_zone_identifier       = aws_subnet.private_subnet.*.id
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = var.web_server_count
  desired_capacity          = var.web_server_count
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Name"
      value               = "web"
      propagate_at_launch = true
    }
  ]
}

module "web-server-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "web-server-alb"

  load_balancer_type = "application"

  vpc_id                           = aws_vpc.vpc.id
  subnets                          = aws_subnet.public_subnet.*.id
  security_groups                  = [aws_security_group.web_alb_sg.id]
  enable_cross_zone_load_balancing = true

  access_logs = {}

  target_groups = [
    {
      name_prefix      = "web-lb"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"

      stickiness = {
        type    = "lb_cookie"
        enabled = true
      }
    }
  ]

  http_tcp_listeners = [
    {
      port     = 80
      protocol = "HTTP"
    }
  ]

  tags = merge({
    Name = "web-alb"
  }, local.tags.common_tags)
}

/*
To be used when not using ASG and instead using aws_instance directly.
resource "aws_lb_target_group_attachment" "web_server_attachment" {
  count            = length(aws_instance.web)
  target_group_arn = module.web-server-alb.target_group_arns[0]
  target_id        = aws_instance.web[count.index].id
  port             = 8080
}
*/
