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
