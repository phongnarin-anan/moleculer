variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "nodejs_ami" {
  type = string
}

variable "nats_ami" {
  type = string
}

variable "obs_ami" {
  type = string
}

variable "secret_id" {
  type = string
}

variable "account_id" {
  type = string
}

variable "virginia_cert_arn" {
  type = string
}

variable "cert_arn" {
  type = string
}
