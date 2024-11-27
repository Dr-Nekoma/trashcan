output "public_ip" {
  value = mgc_virtual_machine_instances.vm.network.public_address
}

output "vm_id" {
  value = mgc_virtual_machine_instances.vm.id
}

output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}
