# -----
# Keys
# -----
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Synchronize the SSH private key to a local file that 
# the "nixos" module can properly use it later
resource "local_sensitive_file" "ssh_private_key" {
  filename = "${path.module}/outputs/id_ed25519"
  content  = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/outputs/id_ed25519.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_key_pair" "ssh_key" {
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# EC2
resource "aws_instance" "vm" {
  ami                         = data.aws_ami.nixos_amd.id
  key_name                    = aws_key_pair.ssh_key.key_name
  instance_type               = var.instance_type
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.vm.id]

  root_block_device {
    volume_size = var.instance_root_volume_size_in_gb
    volume_type = "gp3"
  }

  tags = {
    Category = "vm"
    Project  = "trashcan"
  }
}

# Elastic IP
resource "aws_eip" "eip" {
  domain     = "vpc"
  instance   = aws_instance.vm.id
  depends_on = [aws_internet_gateway.main]

  tags = {
    Category = "ip"
    Project  = "trashcan"
  }
}

# This ensures that the instance is reachable via `ssh` before we deploy NixOS
resource "null_resource" "wait" {
  provisioner "remote-exec" {
    connection {
      host        = aws_eip.eip.public_ip
      private_key = tls_private_key.ssh_key.private_key_openssh
    }

    inline = [":"] # Do nothing; we're just testing SSH connectivity
  }
}

# Installs our Custom NixOS configuration
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
  target_host       = aws_eip.eip.public_ip
  ssh_private_key   = nonsensitive(tls_private_key.ssh_key.private_key_openssh)
  instance_id       = aws_instance.vm.id
  debug_logging     = true
}
