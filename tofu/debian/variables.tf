variable "api_key" {
  type     = string
  nullable = false
}

variable "root_path" {
  type    = string
  nullable = false
}

variable "prefix" {
  type    = string
  default = "trashcan"
}

variable "region" {
  type    = string
  default = "br-se1"
}

variable "vm_type" {
  type    = string
  default = "BV2-8-40"
}


