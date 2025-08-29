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
