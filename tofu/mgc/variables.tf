# ===============
# MGC Variables
# ===============
variable "mgc_api_key" {
  description = "API key to use with the provider."
  sensitive   = true
  type        = string
}

variable "mgc_region" {
  description = "Specifies the region where resources will be created and managed."
  default     = "br-se1"
}

# ===============
# VM Variables
# ===============
variable "instance_type" {
  description = "Instance type for the VM"
  type        = string
  # Options: cloud-bs1.xsmall, cloud-bs1.small, cloud-bs1.medium, etc.
  default = "cloud-bs1.xsmall"
}

variable "initial_image" {
  type    = string
  default = "cloud-ubuntu-24.04 LTS"
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 200
}

# ===============
# NixOS Variables
# ===============
variable "flake_path" {
  description = "Path to your NixOS flake"
  type        = string
  default     = "../.."
  nullable    = false
}

variable "flake_system" {
  description = "NixOS system name in your flake"
  type        = string
  default     = "bootstrap_mgc"
  nullable    = false
}

