terraform {
  required_version = ">= 1.8.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72"
    }
  }
}

variable "ami_version" {
  type    = string
  default = "24.05"
}

variable "region" {
  type     = string
  nullable = false
}

variable "flake" {
  type     = string
  nullable = false
}

provider "aws" {
  profile = "nekoma"
  region  = var.region
}

resource "aws_security_group" "sg" {
  # The "nixos" Terraform module requires SSH access to the machine to deploy
  # our desired NixOS configuration.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Synchronize the SSH private key to a local file that the "nixos" module can
# use
resource "local_sensitive_file" "ssh_private_key" {
  filename = "${path.module}/id_ed25519"
  content  = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/id_ed25519.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_key_pair" "ssh_key" {
  public_key = tls_private_key.ssh_key.public_key_openssh
}

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
  ami = data.aws_ami.nixos_ami.id

  # We could use a smaller instance size, but at the time of this writing the
  # t3.micro instance type is available for 750 hours under the AWS free tier.
  instance_type = "t3.micro"

  # Install the security groups we defined earlier
  security_groups = [aws_security_group.sg.name]

  key_name = aws_key_pair.ssh_key.key_name

  root_block_device {
    volume_size = 64
  }

  user_data = <<-EOF
    #!/bin/sh
    (umask 377; echo '${tls_private_key.ssh_key.private_key_openssh}' > /var/lib/id_ed25519)
    EOF
}

# This ensures that the instance is reachable via `ssh` before we deploy NixOS
resource "null_resource" "wait" {
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.vm.public_dns
      private_key = tls_private_key.ssh_key.private_key_openssh
    }

    inline = [":"] # Do nothing; we're just testing SSH connectivity
  }
}

module "nixos" {
  source      = "github.com/Gabriella439/terraform-nixos-ng//nixos?ref=af1a0af57287851f957be2b524fcdc008a21d9ae"
  host        = "root@${aws_instance.vm.public_ip}"
  flake       = var.flake
  arguments   = []
  ssh_options = "-o StrictHostKeyChecking=accept-new -i ${local_sensitive_file.ssh_private_key.filename}"
  depends_on  = [null_resource.wait]
}

output "public_dns" {
  value = aws_instance.vm.public_dns
}

resource "local_file" "output" {
  content = jsonencode({
    public_dns = aws_instance.vm.public_dns
    public_ip  = aws_instance.vm.public_ip
  })
  filename = "${path.module}/output.json"
}
