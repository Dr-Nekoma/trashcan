# TODO: Add VPC
#resource "mgc_network_vpc" "vpc" {
#  provider    = mgc.se
#  name        = "${var.prefix}-vpc"
#  description = "${var.prefix}-vpc"
#}

resource "mgc_network_security_groups" "sg" {
  name        = "${var.prefix}-${var.region}-sg"
  description = "Security Group"
}

resource "mgc_network_security_groups_rules" "allow_ingress_ssh" {
  depends_on        = [mgc_network_security_groups.sg]
  description       = "Allow Ingress SSH"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 22
  port_range_max    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = mgc_network_security_groups.sg.id
}

resource "mgc_network_security_groups_rules" "allow_ingress_http" {
  depends_on        = [mgc_network_security_groups.sg]
  description       = "Allow Ingress HTTP"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 80
  port_range_max    = 80
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = mgc_network_security_groups.sg.id
}

resource "mgc_network_security_groups_rules" "allow_egress_http" {
  depends_on        = [mgc_network_security_groups.sg]
  description       = "Allow Egress HTTP"
  direction         = "egress"
  ethertype         = "IPv4"
  port_range_min    = 80
  port_range_max    = 80
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = mgc_network_security_groups.sg.id
}

