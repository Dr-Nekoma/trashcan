# ----------
# Variables
# ----------
variable "api_key" {
  type     = string
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

variable "flake" {
  type    = string
  default = "bootstrap"
}

variable "vm_type" {
  type    = string
  default = "BV2-8-40"
}

# ---------
# Provider
# ---------
terraform {
  backend "local" {
    path = ".terraform.tfstate"
  }

  required_providers {
    mgc = {
      source = "registry.terraform.io/magalucloud/mgc"
    }
  }
}

provider "mgc" {
  alias   = "se"
  region  = var.region
  api_key = var.api_key
}

# -----------
# Networking
# -----------
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

# -----
# Keys
# -----
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Synchronize the SSH private key to a local file that
# the "nixos" module can use it.
resource "local_sensitive_file" "ssh_private_key" {
  filename = "${path.module}/id_ed25519"
  content  = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/id_ed25519.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

resource "mgc_ssh_keys" "ssh_key" {
  provider = mgc.se
  name     = "${var.prefix}-ssh"
  key      = tls_private_key.ssh_key.public_key_openssh
}

# ---------------------
# VM Instace + Volumes
# ---------------------
resource "mgc_block_storage_volumes" "volume" {
  name = "${var.prefix}-volume"
  size = 80
  type = {
    name = "cloud_nvme"
  }
}

resource "mgc_virtual_machine_instances" "vm" {
  provider = mgc.se
  name     = var.prefix

  machine_type = {
    name = var.vm_type
  }

  image = {
    name = "cloud-debian-12 LTS"
  }

  network = {
    associate_public_ip = true

    #vpc = {
    #  id = mgc_network_vpc.vpc.network_id
    #}

    interface = {
      security_groups = [{
        id = mgc_network_security_groups.sg.id
      }]
    }
  }

  user_data = filebase64("${path.module}/templates/user_data.sh")

  ssh_key_name = mgc_ssh_keys.ssh_key.name
}

# Attaching the VM with Block Storage
resource "mgc_block_storage_volume_attachment" "va" {
  block_storage_id   = mgc_block_storage_volumes.volume.id
  virtual_machine_id = mgc_virtual_machine_instances.vm.id
}

# This ensures that the instance is reachable via `ssh` before we deploy NixOS
resource "null_resource" "wait" {
  provisioner "remote-exec" {
    connection {
      host        = mgc_virtual_machine_instances.vm.network.public_address
      private_key = tls_private_key.ssh_key.private_key_openssh
    }

    inline = [":"] # Do nothing; we're just testing SSH connectivity
  }
}

# -------------
# Provisioning
# -------------
module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${var.flake}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${var.flake}.config.system.build.diskoScript"
  debug_logging          = true

  instance_id  = mgc_virtual_machine_instances.vm.id
  target_host  = mgc_virtual_machine_instances.vm.network.public_address
  install_user = "debian"
}

# -------
# Outputs
# -------
output "public_ip" {
  value = mgc_virtual_machine_instances.vm.network.public_address
}

resource "local_file" "nix_output" {
  content = templatefile(
    "${path.module}/templates/secrets.nix.tftpl",
    { server_public_key = tls_private_key.ssh_key.public_key_openssh }
  )
  filename = "${path.module}/secrets/secrets.nix"
}

resource "local_file" "output" {
  content = jsonencode({
    public_ip = mgc_virtual_machine_instances.vm.network.public_address
  })
  filename = "${path.module}/output.json"
}
