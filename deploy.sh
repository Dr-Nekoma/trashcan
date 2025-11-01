#!/usr/bin/env bash

set -euo pipefail

TARGET_FLAKE=${TARGET_FLAKE:-"bootstrap"}
TARGET_PLATFORM=${TARGET_PLATFORM:-"vm"}
TARGET_HOST=""
TARGET_SSH_FILE="/var/lib/agenix/id_ed25519"
HELP="Usage: $0 --target-flake <flake> --target-host <host> --target-platform <aws|mgc>"

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --target-flake)
            TARGET_FLAKE="$2"
            shift 2
            ;;
        --target-platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "$HELP"
            exit 1
            ;;
    esac
done

case "${TARGET_PLATFORM}" in
    "aws")
        TARGET_HOST="nekoma_aws"
        ;;
    "mgc")
        TARGET_HOST="nekoma_mgc"
        ;;
    "vm")
        TARGET_HOST="nekoma_vm"
        ;;
    *)
        echo "$HELP"
        exit 1
        ;;
esac

rsync -avz --chown root:root "$HOME/.ssh/trashcan_server" $TARGET_HOST:$TARGET_SSH_FILE

printf "\n\tDEPLOYING FLAKE=%s to TARGET=%s\n\n" "$TARGET_FLAKE" "$TARGET_HOST"

nix run nixpkgs#nixos-rebuild switch -- \
    -j auto \
    --use-remote-sudo \
    --flake ".#$TARGET_FLAKE" \
    --build-host localhost \
    --target-host "$TARGET_HOST"
