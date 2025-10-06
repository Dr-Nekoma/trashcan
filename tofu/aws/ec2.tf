locals {
  host_settings = fileset(".", "../outputs/hosts.json")
}

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

  user_data = <<-EOF
    #!/usr/bin/env bash
    mkdir -p etc/ssh var/lib/secrets
    (umask 377; echo '${tls_private_key.ssh_key.private_key_openssh}' > /var/lib/secrets/id_ed25519)
  EOF

  root_block_device {
    volume_size = 100
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

# Now install the first bootstrap flake
module "nixos_anywhere" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr = "${var.flake_path}#nixosConfigurations.${var.flake_system}.config.system.build.toplevel"
  # nixos_partitioner_attr = "${var.flake_path}#nixosConfigurations.${var.flake_system}.config.system.build.diskoScript"
  instance_id = aws_instance.vm.id
  # install_user           = "root"
  target_host        = aws_eip.eip.public_ip
  install_ssh_key    = nonsensitive(tls_private_key.ssh_key.private_key_openssh)
  deployment_ssh_key = nonsensitive(tls_private_key.ssh_key.private_key_openssh)

  special_args = {
    terraform_ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  }

  # Useful on first time setups and debugging
  debug_logging   = true
  build_on_remote = true

  depends_on = [
    null_resource.wait
  ]
}
