output "public_dns" {
  value = aws_eip.eip.public_dns
}

resource "local_file" "output" {
  content = jsonencode({
    public_dns = aws_eip.eip.public_dns
    public_ip  = aws_eip.eip.public_ip
  })
  filename = "${path.module}/outputs/output.json"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i outputs/id_ed25519 root@${aws_eip.eip.public_dns}"
}
