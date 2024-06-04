variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "team" {
  type = string
}

variable "vpc" {
  type = object({
    cidr_ipv4 = string
  })
  description = "Define vpc cidr block"
}

variable "public_subnets" {
  type = map(object({
    cidr_ipv4         = string
    availability_zone = string
  }))
  description = "Define list of public subnet cidr blocks"
  default     = {}
}

variable "private_subnets" {
  type = map(object({
    cidr_ipv4         = string
    availability_zone = string
  }))
  description = "Define list of public subnet cidr blocks"
  default     = {}
}