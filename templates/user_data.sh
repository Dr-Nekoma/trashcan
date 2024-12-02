#!/bin/sh
(umask 377; echo '${tls_private_key.ssh_key.private_key_openssh}' > /var/lib/id_ed25519)
