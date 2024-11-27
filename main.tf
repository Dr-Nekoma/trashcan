terraform {
  backend "local" {
    path = ".terraform.tfstate"
  }
}

module "vm" {
  source    = "./tofu/debian"
  api_key   = var.api_key
  root_path = abspath(path.root)
}

module "nixos" {
  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${var.flake}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${var.flake}.config.system.build.diskoScript"
  debug_logging          = true
  deployment_ssh_key     = file("${path.root}/id_ed25519")

  instance_id  = module.vm.vm_id
  target_host  = module.vm.public_ip
  install_user = "debian"
}

resource "local_file" "nix_output" {
  content = templatefile(
    "${path.root}/templates/secrets.nix.tftpl",
    { server_public_key = module.vm.public_key }
  )
  filename = "${path.root}/secrets/secrets.nix"
}

resource "local_file" "output" {
  content = jsonencode({
    public_ip = module.vm.public_ip
  })
  filename = "${path.root}/output.json"
}
