resource "mgc_network_vpcs" "vpc" {
  name        = "vpc-nekoma"
  description = "Nekoma VPC"
}

# Public Subnet
resource "mgc_network_subnetpools" "snet_pool" {
  name        = "snet-pool-pub-nekoma"
  description = "Nekoma Subnet Pool"
  cidr        = "10.0.0.0/16"
}

resource "mgc_network_vpcs_subnets" "snet_pub" {
  cidr_block      = "10.0.0.0/24"
  description     = "Public VPC Subnet"
  ip_version      = "IPv4"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  name            = "snet-pub-nekoma"
  subnetpool_id   = mgc_network_subnetpools.snet_pool.id
  vpc_id          = mgc_network_vpcs.vpc.id
}

# Create Security Group
resource "mgc_network_security_groups" "sg_vm" {
  name        = "sg-nekoma"
  description = "Security group for the Nekoma server"
}

# Security Group Rule - SSH
resource "mgc_network_security_groups_rules" "allow_ssh" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow SSH access"
}

# Security Group Rule - EPMD
resource "mgc_network_security_groups_rules" "allow_epmd" {
  security_group_id = mgc_network_security_groups.sg_vm.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 4369
  port_range_max    = 4369
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Allow EPMD port"
}

# Egress
# resource "mgc_network_security_groups_rules" "egress" {
#   description       = "Allow all outbound traffic"
#   security_group_id = mgc_network_security_groups.sg_vm.id
#   direction         = "egress"
#   ethertype         = "IPv4"
#   remote_ip_prefix  = "0.0.0.0/0"
# }

# Attach SG to VPC
# resource "mgc_network_vpcs_interfaces" "vpci" {
#   name   = "vpc-nekoma"
#   vpc_id = mgc_network_vpcs.vpc.id
# }
#
# resource "mgc_network_security_groups_attach" "vpci_attach" {
#   security_group_id = mgc_network_security_groups.sg_vm.id
#   interface_id      = mgc_network_vpcs_interfaces.vpci.id
# }

# Public IPs
resource "mgc_network_public_ips" "ip" {
  vpc_id = mgc_network_vpcs.vpc.id
}
