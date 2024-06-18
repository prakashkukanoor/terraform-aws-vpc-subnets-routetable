variable "region" {
  type = string
}

variable "environment" {
  type = string
}
variable "team" {
  type = string
}

variable "vpc" {
  type = object({
    cidr_block_ipv4 = string
  })
}

variable "dmz_subnets" {
  type = list(string)
}
variable "webserver_subnets" {
  type = list(string)
}
variable "database_subnets" {
  type = list(string)
}
variable "availability_zones" {
  type = list(string)
}