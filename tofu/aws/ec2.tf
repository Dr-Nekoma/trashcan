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
  instance_type = var.instance_type
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.vm.id]

  user_data_base64 = base64encode(templatefile("${path.module}/user-data.sh", {
    flake_url = var.flake_url,
    flake_system = var.flake_system,
    private_key = tls_private_key.ssh_key.private_key_openssh
  }))

  user_data = <<-EOF
    #!/usr/bin/env bash
    (umask 377; echo '${tls_private_key.ssh_key.private_key_openssh}' > /var/lib/id_ed25519)

    mkdir -p /etc/nix
    cat > /etc/nix/nix.conf << EOL
    experimental-features = nix-command flakes
    EOL

    systemctl restart nix-daemon
    sleep 30

    nix shell nixpkgs#git
    echo "Deploying NixOS configuration from flake: ${var.flake_url}#${var.flake_system}"
    nixos-rebuild switch --flake "${var.flake_url}#${var.flake_system}" --show-trace

    systemctl enable sshd
    systemctl start sshd

    echo "NixOS deployment complete!"
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

# module "deploy" {
#   source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
#   
#   nixos_system_attr = ".#nixosConfigurations.${var.flake_system}.config.system.build.toplevel"
#   nixos_partitioner_attr = ".#nixosConfigurations.hetzner-cloud.config.system.build.disko"
#   target_host = hcloud_server.nixos.ipv4_address
#   instance_id = hcloud_server.nixos.id
#   debug_logging = true
#
#   extra_files_script = <<-EOT
#     #!/usr/bin/env bash
#     set -euo pipefail
#     
#     mkdir -p etc/ssh/authorized_keys.d
#     printf "%s" "${var.sshKeys}" > etc/ssh/authorized_keys.d/root
#     printf "%s" "${var.sshKeys}" > etc/ssh/authorized_keys.d/patrick
#     chmod 755 etc/ssh/authorized_keys.d
#     chmod 600 etc/ssh/authorized_keys.d/root
#     chmod 600 etc/ssh/authorized_keys.d/patrick
#   EOT
#
#   depends_on = [aws_instance.vm]
# }

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
