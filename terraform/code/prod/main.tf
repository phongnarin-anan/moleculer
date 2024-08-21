variable "region" {
  type = string
}

variable "account_id" {
  type = string
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

variable "virginia_cert_arn" {
  type = string
}

variable "cert_arn" {
  type = string
}

module "moleculer" {
  source            = "../module/"
  vpc_cidr          = var.vpc_cidr
  nodejs_ami        = var.nodejs_ami
  nats_ami          = var.nats_ami
  obs_ami           = var.obs_ami
  secret_id         = var.secret_id
  account_id        = var.account_id
  virginia_cert_arn = var.virginia_cert_arn
  cert_arn          = var.cert_arn
}
