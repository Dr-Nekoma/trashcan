output "static_ip" {
  description = "Static IP address"
  value       = mgc_network_public_ips.ip.public_ip
}

resource "local_file" "output" {
  content = jsonencode({
    public_ip = mgc_network_public_ips.ip.public_ip
  })
  filename = "${path.module}/outputs/output.json"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i outputs/id_ed25519 root@${mgc_network_public_ips.ip.public_ip}"
}
