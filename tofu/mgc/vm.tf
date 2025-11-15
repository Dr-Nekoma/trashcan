# SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  filename = "${path.module}/outputs/id_ed25519"
  content  = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/outputs/id_ed25519.pub"
  content  = tls_private_key.ssh_key.public_key_openssh
}

resource "mgc_ssh_keys" "deploy_key" {
  name = "ssh-deploy-key"
  key  = tls_private_key.ssh_key.public_key_openssh
}

# VM Instances
resource "mgc_virtual_machine_instances" "nixos_vm" {
  name         = "nixos-instance"
  machine_type = var.instance_type
  ssh_key_name = mgc_ssh_keys.deploy_key.name
  image        = var.initial_image
  vpc_id       = mgc_network_vpcs.vpc.id

  depends_on = [
    mgc_network_vpcs.vpc
  ]
}

# Associate IP -> VM
resource "mgc_network_public_ips_attach" "aip" {
  public_ip_id = mgc_network_public_ips.ip.id
  interface_id = mgc_virtual_machine_instances.nixos_vm.network_interface_id
}

# NixOS Deploy
module "nixos" {
  source = "../nixos"

  debug_logs             = true
  bootstrap_flake_system = "bootstrap_mgc"
  final_flake_system     = "nekoma_mgc"
  instance_id            = mgc_virtual_machine_instances.nixos_vm.id
  default_user           = "ubuntu"
  public_ip              = mgc_network_public_ips.ip.public_ip
  private_openssh_key    = tls_private_key.ssh_key.private_key_openssh
  public_openssh_key     = tls_private_key.ssh_key.public_key_openssh

  depends_on = [
    mgc_network_public_ips.ip,
    mgc_network_public_ips_attach.aip,
    mgc_virtual_machine_instances.nixos_vm
  ]
}
