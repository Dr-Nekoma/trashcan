resource "mgc_network_vpc" "vpc" {
  name        = "vpc-nekoma"
  description = "Main VPC"
  cidr_block  = "10.0.0.0/16"
}

resource "mgc_network_vpcs_interfaces" "vpci" {
  name   = "vpci-nekoma"
  vpc_id = mgc_network_vpcs.vpc.id
}

# Public Subnet
resource "mgc_network_subnet" "net_pub" {
  name       = "snet-nekoma"
  vpc_id     = mgc_network_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  # Enable auto-assign public IP for instances in this subnet
  map_public_ip_on_launch = true
}

# Create Security Group
resource "mgc_network_security_group" "sg_vm" {
  name        = "sg-nekoma"
  description = "Security group for the Nekoma server"
  vpc_id      = mgc_network_vpc.vpc.id
}

# Security Group Rule - SSH
resource "mgc_network_security_group_rules" "allow_ssh" {
  security_group_id = mgc_network_security_group.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  cidr_block        = "0.0.0.0/0"
  description       = "Allow SSH access"
}

# Security Group Rule - EPMD
resource "mgc_network_security_group_rules" "allow_epmd" {
  security_group_id = mgc_network_security_group.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 4369
  port_range_max    = 4369
  cidr_block        = "0.0.0.0/0"
  description       = "Allow EPMD access"
}

# Public IPs
resource "mgc_network_public_ips" "ip" {
  vpc_id = mgc_network_vpc.vpc.id
}
