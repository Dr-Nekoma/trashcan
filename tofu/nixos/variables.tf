# Agenix
variable "local_identity_key_path" {
  description = "The local path where your Agenix identity key is."
  type        = string
  default     = "~/.ssh/trashcan_server"
  nullable    = false
}

variable "destination_path" {
  description = "The path where the Agenix identity key is supposed to be"
  type        = string
  default     = "/var/lib/agenix/id_ed25519"
  nullable    = false
}

# Keys
variable "default_user" {
  description = "The default user used in the first NixOS Install"
  type        = string
  default     = "root"
  nullable    = false
}

variable "private_openssh_key" {
  type     = string
  nullable = false
}

variable "public_openssh_key" {
  type     = string
  nullable = false
}

# Nix
variable "debug_logs" {
  type     = bool
  default  = false
  nullable = false
}

variable "flake_path" {
  description = "NixOS flake URL (either a local path or git repo)"
  type        = string
  default     = "../.."
  nullable    = false
}

variable "bootstrap_flake_system" {
  type     = string
  nullable = false
}

variable "final_flake_system" {
  type     = string
  nullable = false
}

# VM
variable "instance_id" {
  type     = string
  nullable = false
}

variable "public_ip" {
  type     = string
  nullable = false
}
