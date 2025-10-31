output "static_ip" {
  description = "Static IP address"
  value       = mgc_network_public_ips.static_ip.ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i outputs/id_ed25519 root@${mgc_network_public_ips.static_ip.ip}"
}
