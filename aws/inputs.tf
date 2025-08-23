variable "ami_version" {
  type    = string
  default = "25.11"
}

variable "vm_private_ip" {
  type    = string
  default = "10.0.0.12"
}

variable "region" {
  type     = string
  nullable = false
}

variable "flake" {
  type     = string
  nullable = false
}
