# terraform-test

# I sense a disturbance in the traffic flow

## Task

There is a web server here which is listening on port 80. Modify the Terraform configuration to make it high availability. Anything else to improve?

The Terraform configuration will ask you to enter an SSH key name to setup the EC2 instance.

## Validation

* Can withstand loss of an availability zone.
* Reasonable security.

# Task List which has been achieved:
1. Subnet has to be in multi-AZ
2. Autoscaling group needs to be in place.
3. Need to have LB in front
4. Put web instance in the private subnet.
5. Security group of web instance to talk to LB security group only.


# Further improvements:
1. use modules for VPC part
2. Add vpn instance to access web instance from private subnet, or just bake ssm agent in the instances and access from system manager.
3. Cloudfront?
4. Route53 entry in place.
5. Remote state
