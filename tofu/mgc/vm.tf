# SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  filename = "${path.module}/outputs/id_ed25519"
  content  = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/outputs/id_ed25519.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

resource "mgc_ssh_keys" "deploy_key" {
  name = "ssh-deploy-key"
  key  = tls_private_key.ssh_key.public_key_openssh
}

# VM Instances
resource "mgc_virtual_machine_instances" "nixos_vm" {
  name         = "nixos-instance"
  machine_type = var.instance_type
  ssh_key_name = mgc_ssh_keys.deploy_key.name
  image        = var.initial_image
  vpc_id       = mgc_network_vpcs.vpc.id

  depends_on = [
    mgc_network_vpcs.vpc
  ]
}

# Associate IP -> VM
resource "mgc_network_public_ips_attach" "aip" {
  public_ip_id = mgc_network_public_ips.ip.id
  interface_id = mgc_virtual_machine_instances.nixos_vm.network_interface_id
}

# Wait for SSH to be ready
resource "null_resource" "wait_for_ssh" {
  depends_on = [
    mgc_virtual_machine_instances.nixos_vm,
    mgc_network_public_ips.ip
  ]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = mgc_network_public_ips.ip.public_ip
      private_key = tls_private_key.ssh_key.private_key_openssh
      timeout     = "15m"
    }

    # Do nothing; we're just testing SSH connectivity
    inline = [":"]
  }
}

# Deploy NixOS using nixos-anywhere
module "system_build" {
  source        = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute     = "${var.flake_path}#nixosConfigurations.${var.flake_system}.config.system.build.toplevel"
  debug_logging = true

  special_args = {
    terraform_ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  }
}

module "disko_build" {
  source        = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute     = "${var.flake_path}#nixosConfigurations.${var.flake_system}.config.system.build.diskoScript"
  debug_logging = true

  special_args = {
    terraform_ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  }

  depends_on = [module.system_build]
}

module "install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.system_build.result.out
  nixos_partitioner = module.disko_build.result.out
  target_host       = mgc_network_public_ips.ip.public_ip
  ssh_private_key   = nonsensitive(tls_private_key.ssh_key.private_key_openssh)
  instance_id       = mgc_virtual_machine_instances.nixos_vm.id
  target_user       = "ubuntu"
  debug_logging     = true
}
