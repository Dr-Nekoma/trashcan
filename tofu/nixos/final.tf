# After State 1 is done, we proceed to setup the
# second stage, which involves:
#
#    1. Adding a Private Key to the newly deployed VM
#    2. Building the full NixOS configuration with all the modules enabled
resource "null_resource" "copy_ssh_key" {
  triggers = {
    instance_id = var.instance_id
  }

  connection {
    type        = "ssh"
    host        = var.public_ip
    user        = "root"
    private_key = var.private_openssh_key
  }

  # First, create the destination directory if it doesn't exist
  provisioner "remote-exec" {
    inline = [
      "set -eux",
      "echo 'Creating destination directory...'",
      "mkdir -p $(dirname ${var.destination_path})",
      "ls -la $(dirname ${var.destination_path}) || true"
    ]
  }

  # Then copy the file
  provisioner "file" {
    source      = pathexpand(var.local_identity_key_path)
    destination = var.destination_path
  }

  # Finally, set permissions and verify
  provisioner "remote-exec" {
    inline = [
      "set -eux",
      "echo 'Setting permissions...'",
      "chown root:root ${var.destination_path}",
      "chmod 400 ${var.destination_path}",
      "echo 'Verifying file was copied...'",
      "ls -lh ${var.destination_path}",
      "echo 'SSH key successfully copied to ${var.destination_path}'"
    ]
  }

  depends_on = [module.bootstrap_install]
}

# Stage 2
# Build the full system configuration
module "final_build" {
  source        = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute     = "${var.flake_path}#nixosConfigurations.${var.final_flake_system}.config.system.build.toplevel"
  debug_logging = var.debug_logs

  special_args = {
    terraform_ssh_public_key = var.public_openssh_key
  }

  depends_on = [null_resource.copy_ssh_key]
}

# https://github.com/nix-community/nixos-anywhere/blob/main/terraform/nixos-rebuild.md
module "final_rebuild" {
  source          = "github.com/nix-community/nixos-anywhere//terraform/nixos-rebuild"
  nixos_system    = module.final_build.result.out
  target_host     = var.public_ip
  ssh_private_key = nonsensitive(var.private_openssh_key)

  depends_on = [null_resource.copy_ssh_key]
}
