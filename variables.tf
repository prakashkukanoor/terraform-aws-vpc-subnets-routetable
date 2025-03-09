variable "region" {
  type = string
}

variable "environment" {
  type = string
}
variable "team" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "enable_ipv6" {
  type = bool
}

variable "vpc_cidr_ipv4" {
  type = string
}

variable "application_public_subnets" {
  type = list(object({
    az        = string
    ipv4_cidr = string
  }))
}

# variable "application_private_subnets" {
#   type = list(string)
# }

# variable "database_private_subnets" {
#   type = list(string)
# }



