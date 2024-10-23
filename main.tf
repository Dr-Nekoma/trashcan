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

variable "vm_private_ip" {
  type    = string
  default = "10.0.0.12"
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

locals {
  availability_zone = "${var.region}c"
}

# -----------
# Networking
# -----------
# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Category = "network"
    Project  = "trashcan"
  }
}

# Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

# Subnet
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = local.availability_zone

  # This makes it a public subnet
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.gw]

  tags = {
    Category = "network"
    Project  = "trashcan"
  }
}

# Create Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Category = "network"
    Project  = "trashcan"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

# Security Group
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id

  # The "nixos" Terraform module requires SSH access to the machine to deploy
  # our desired NixOS configuration.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Category = "network"
    Project  = "trashcan"
  }
}

# -----
# Keys
# -----
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

# -------
# Outputs
# -------
output "public_dns" {
  value = aws_eip.eip.public_dns
}

resource "local_file" "nix_output" {
  content = templatefile(
    "${path.module}/templates/secrets.nix.tftpl",
    { server_public_key = tls_private_key.ssh_key.public_key_openssh }
  )
  filename = "${path.module}/secrets/secrets.nix"
}

resource "local_file" "output" {
  content = jsonencode({
    public_dns = aws_eip.eip.public_dns
    public_ip  = aws_eip.eip.public_ip
  })
  filename = "${path.module}/output.json"
}
