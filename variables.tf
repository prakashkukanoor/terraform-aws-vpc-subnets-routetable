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
  type = list(object({
    ipv4_cidr  = string
    ipv6_index = number
  }))
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

variable "vpc_endpoints" {
  type = map(bool)
  default = {
    s3        = true
    dynamodb  = true
  }
}


