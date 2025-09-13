variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "a"
  nullable = false
}

variable "instance_type" {
  description = "The instance used by the AMI and EC2"
  type        = string
  default     = "t3.small"
  nullable = false
}

variable "project" {
  type        = string
  default     = "trashcan"
  nullable = false
}

variable "region" {
  type    = string
  default = "us-east-1"
  nullable = false
}

# ===============
# NixOS Variables
# ===============
variable "ami_version" {
  description = "NixOS AMI version"
  type        = string
  default     = "25.05"
  nullable = false
}

variable "flake_url" {
  description = "NixOS flake URL (either a local path or git repo)"
  type        = string
  default     = "github:Dr-Nekoma/trashcan/25-REFACTOR-deploy"
  nullable = false
}

variable "flake_system" {
  description = "NixOS flake system to be use"
  type        = string
  default     = "bootstrap"
  nullable = false
}

