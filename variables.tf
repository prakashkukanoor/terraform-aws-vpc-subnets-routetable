variable "region" {
  type = string
}

variable "environment" {
  type = string
}
variable "team" {
  type = string
}

variable "enable_ipv6" {
  type = bool
}

variable "vpc_cidr_ipv4" {
  type = string
}

variable "availability_zone" {
  type = list(string)
}

variable "application_public_subnets" {
  type = map(object({
    ipv4_cidr  = string
    ipv6_index = number
  }))
  default = {
    "Application-Public-Subnet-01" = {
      az = "us-east-1a"
      ipv4_cidr = "10.0.0.0/24"
      ipv6_index = 0
    }
    "Application-Public-Subnet-02" = {
      az = "us-east-1b"
      ipv4_cidr = "10.0.1.0/24"
      ipv6_index = 1
    }
    "Application-Public-Subnet-03" = {
      az = "us-east-1c"
      ipv4_cidr = "10.0.2.0/24"
      ipv6_index = 2
    }
  }
  
}

variable "application_private_subnets" {
  type = list(object({
    ipv4_cidr  = string
    ipv6_index = number
  }))
}

variable "database_private_subnets" {
  type = list(object({
    ipv4_cidr  = string
    ipv6_index = number
  }))
}

variable "vpc_gateway_endpoints" {
  type = map(bool)
  default = {
    s3       = true
    dynamodb = true
  }
}

variable "vpc_interface_endpoints" {
  type = map(bool)
  default = {
    events = true
  }
}


