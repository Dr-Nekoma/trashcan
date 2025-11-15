# This ensures that the instance is reachable via `ssh` before we deploy NixOS
resource "null_resource" "wait" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.default_user
      host        = var.public_ip
      private_key = var.private_openssh_key
      timeout     = "15m"
    }

    # Do nothing; we're just testing SSH connectivity
    inline = [":"]
  }

  depends_on = [
    var.instance_id
  ]
}

# Stage 1
# Installs our Custom NixOS configuration in "boostrap mode"
module "bootstrap_build" {
  source        = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute     = "${var.flake_path}#nixosConfigurations.${var.bootstrap_flake_system}.config.system.build.toplevel"
  debug_logging = var.debug_logs

  special_args = {
    terraform_ssh_public_key = var.public_openssh_key
  }

  depends_on = [null_resource.wait]
}

module "disko_build" {
  source        = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute     = "${var.flake_path}#nixosConfigurations.${var.bootstrap_flake_system}.config.system.build.diskoScript"
  debug_logging = var.debug_logs

  special_args = {
    terraform_ssh_public_key = var.public_openssh_key
  }

  depends_on = [module.bootstrap_build]
}

module "bootstrap_install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.bootstrap_build.result.out
  nixos_partitioner = module.disko_build.result.out
  target_host       = var.public_ip
  target_user       = var.default_user
  ssh_private_key   = nonsensitive(var.private_openssh_key)
  instance_id       = var.instance_id
  debug_logging     = var.debug_logs
}
