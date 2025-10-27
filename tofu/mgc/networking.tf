resource "mgc_virtual_machine_instances_networks" "vpc" {
  provider    = mgc.sudeste
  name        = "nixos-vpc"
  description = "VPC for NixOS deployment"
}

# Public Subnet
resource "mgc_virtual_machine_instances_network_subnets" "public" {
  provider   = mgc.sudeste
  name       = "nixos-public-subnet"
  network_id = mgc_virtual_machine_instances_networks.vpc.id
  cidr_block = "10.0.1.0/24"
}

# Security Group
resource "mgc_virtual_machine_instances_security_groups" "nixos_sg" {
  provider    = mgc.sudeste
  name        = "nixos-security-group"
  description = "Allow SSH access"
}

resource "mgc_virtual_machine_instances_security_groups_rules" "allow_ssh" {
  provider          = mgc.sudeste
  security_group_id = mgc_virtual_machine_instances_security_groups.nixos_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_max    = 22
  port_range_min    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "mgc_virtual_machine_instances_security_groups_rules" "allow_all_outbound" {
  provider          = mgc.sudeste
  security_group_id = mgc_virtual_machine_instances_security_groups.nixos_sg.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = null
  remote_ip_prefix  = "0.0.0.0/0"
}

# Get Ubuntu 22.04, then replace it with NixOS
# using nixos-anywhere:
#   https://github.com/nix-community/nixos-anywhere
data "mgc_virtual_machine_instances_images" "ubuntu" {
  provider = mgc.sudeste
  name     = "cloud-ubuntu-22.04 LTS"
}

data "mgc_virtual_machine_instances_availability_zones" "available" {
  provider = mgc.sudeste
}
