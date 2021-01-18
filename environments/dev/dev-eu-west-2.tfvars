aws_region           = "eu-west-2"
ssh_key              = "manish-test"
web_server_count     = 2
ami_id               = "ami-0e937c3451fac7084"
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.3.0/24", "10.1.5.0/24"]
private_subnet_cidrs = ["10.1.2.0/24", "10.1.4.0/24", "10.1.6.0/24"]
