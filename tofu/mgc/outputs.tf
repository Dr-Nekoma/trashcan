output "instance_id" {
  description = "Instance ID"
  value       = mgc_virtual_machine_instances.nixos_vm.id
}

output "static_ip" {
  description = "Static IP address"
  value       = mgc_network_public_ips.static_ip.ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i outputs/id_ed25519 root@${mgc_network_public_ips.static_ip.ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = mgc_virtual_machine_instances_networks.vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = mgc_virtual_machine_instances_network_subnets.public.id
}
