# SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  filename        = "${path.module}/outputs/id_ed25519"
  content         = tls_private_key.ssh_key.private_key_openssh
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/outputs/id_ed25519.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

resource "mgc_ssh_keys" "deploy_key" {
  name     = "nixos-deploy-key"
  key      = tls_private_key.ssh_key.public_key_openssh
}

# VM Instances
resource "mgc_virtual_machine_instances" "nixos_vm" {
  name     = "nixos-instance"
  machine_type = var.instance_type
  ssh_key_name = mgc_ssh_keys.deploy_key.name
  image = var.initial_image
}

# Associate IP -> VM
resource "mgc_network_public_ips_attach" "aip" {
  public_ip  = mgc_network_public_ips.ip.id
  network_id = mgc_virtual_machine_instances.nixos_vm.network.interface.id
  type       = "virtual_machine_interface"
}

resource "mgc_virtual_machine_interface_attach" "attach_vm" {
  instance_id  = mgc_virtual_machine_instances.nixos_vm.id
  interface_id = mgc_network_vpcs_interfaces.vpci.id
}

# Wait for SSH to be ready
resource "null_resource" "wait_for_ssh" {
  depends_on = [
    mgc_virtual_machine_instances.nixos_vm,
    mgc_network_public_ips_attach.vm_ip
  ]

  provisioner "remote-exec" {
    connection {
      host        = mgc_network_public_ips.static_ip.ip
      user        = "ubuntu"
      private_key = tls_private_key.ssh_key.private_key_openssh
      timeout     = "15m"
    }

    inline = [":"]
  }
}

# Deploy NixOS using nixos-anywhere
module "nixos_anywhere" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  nixos_system_attr      = "${var.flake_path}#nixosConfigurations.${var.flake_system}.config.system.build.toplevel"
  nixos_partitioner_attr = "${var.flake_path}#nixosConfigurations.${var.flake_system}.config.system.build.diskoScript"

  instance_id = mgc_virtual_machine_instances.nixos_vm.id
  target_host = mgc_network_public_ips.static_ip.ip
  # Ubuntu is the default user for Magalu Cloud Ubuntu images
  install_user = "ubuntu"

  install_ssh_key    = nonsensitive(tls_private_key.ssh_key.private_key_openssh)
  deployment_ssh_key = nonsensitive(tls_private_key.ssh_key.private_key_openssh)

  special_args = {
    terraform_ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  }

  debug_logging   = true
  build_on_remote = false

  depends_on = [
    null_resource.wait_for_ssh
  ]
}
