# -----
# Keys
# -----
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Synchronize the SSH private key to a local file that
# the "nixos" module can use it.
resource "local_sensitive_file" "ssh_private_key" {
  filename = "${var.root_path}/id_ed25519"
  content  = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_public_key" {
  filename = "${var.root_path}/id_ed25519.pub"
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
# TODO: Debug why this hangs when attaching to the VM
#resource "mgc_block_storage_volumes" "volume" {
#  name = "${var.prefix}-volume"
#  size = 80
#  type = {
#    name = "cloud_nvme"
#  }
#}

resource "mgc_virtual_machine_instances" "vm" {
  provider = mgc.se
  name     = var.prefix
  name_is_prefix = true

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

  user_data = filebase64("${var.root_path}/templates/user_data.sh")

  ssh_key_name = mgc_ssh_keys.ssh_key.name
}

# Attaching the VM with Block Storage
#resource "mgc_block_storage_volume_attachment" "va" {
#  block_storage_id   = mgc_block_storage_volumes.volume.id
#  virtual_machine_id = mgc_virtual_machine_instances.vm.id
#}

# This ensures that the instance is reachable via `ssh` before we deploy NixOS
#resource "null_resource" "wait" {
#  provisioner "remote-exec" {
#    connection {
#      host        = mgc_virtual_machine_instances.vm.network.public_address
#      private_key = tls_private_key.ssh_key.private_key_openssh
#    }
#
#    inline = [":"] # Do nothing; we're just testing SSH connectivity
#  }
#}

