# terraform-aws-vpc-subnets
This module can be imported to create below resource in AWS
- vpc
- public subnets
    - Route tables will be created
    - Route table will have Internet Gateway attached
- private subnets
    - Route table will be created
    - NAT gateway (public facing) will be attached to the route table

