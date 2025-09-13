#!/bin/bash
set -euo pipefail

# To be used by the real deploy later
(umask 377; echo '${private_key}' > /var/lib/id_ed25519)

# Enable flakes for the first-time setup
mkdir -p /etc/nix
cat > /etc/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF

# Restart nix daemon
systemctl restart nix-daemon

# Wait for network to be ready
sleep 30

# Deploy the flake
nix shell nixpkgs#git
echo "Deploying NixOS configuration from flake: ${flake_url}#${flake_system}"
nixos-rebuild switch --flake "${flake_url}#${flake_system}" --show-trace

# Ensure SSH is enabled and started
systemctl enable sshd
systemctl start sshd

echo "NixOS deployment complete!"
