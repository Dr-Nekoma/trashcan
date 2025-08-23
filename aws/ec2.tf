# ------------
# EC2 Instance
# ------------
data "aws_ami" "nixos_ami" {
  most_recent = true

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["nixos/${var.ami_version}*"]
  }

  owners = ["427812963091"]
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.nixos_ami.id
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  key_name                    = aws_key_pair.ssh_key.key_name
  private_ip                  = var.vm_private_ip
  associate_public_ip_address = false

  # We could use a smaller instance size, but at the time of this writing the
  # t3.micro instance type is available for 750 hours under the AWS free tier.
  instance_type = "t3.micro"

  root_block_device {
    volume_size = 80
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/sh
    (umask 377; echo '${tls_private_key.ssh_key.private_key_openssh}' > /var/lib/id_ed25519)
    EOF

  tags = {
    Category = "vm"
    Project  = "trashcan"
  }
}

# ----------
# Static IP
# ----------
resource "aws_eip" "eip" {
  domain                    = "vpc"
  instance                  = aws_instance.vm.id
  associate_with_private_ip = var.vm_private_ip
  depends_on                = [aws_internet_gateway.gw]
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

module "nixos" {
  source      = "github.com/Gabriella439/terraform-nixos-ng//nixos?ref=af1a0af57287851f957be2b524fcdc008a21d9ae"
  host        = "root@${aws_eip.eip.public_ip}"
  flake       = var.flake
  arguments   = []
  ssh_options = "-o StrictHostKeyChecking=accept-new -i ${local_sensitive_file.ssh_private_key.filename}"
  depends_on  = [null_resource.wait]
}
