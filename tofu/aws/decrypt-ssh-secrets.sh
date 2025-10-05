#!/usr/bin/env bash

mkdir -p etc/ssh var/lib/secrets

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

umask 0177
sops --extract '["initrd_ssh_key"]' --decrypt "$SCRIPT_DIR/secrets.yaml" >./var/lib/secrets/initrd_ssh_key

# restore umask
umask 0022

for keyname in ssh_host_rsa_key ssh_host_rsa_key.pub ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  sops --extract '["'$keyname'"]' --decrypt "$SCRIPT_DIR/secrets.yaml" >"./etc/ssh/$keyname"
done
