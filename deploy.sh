#!/usr/bin/env bash

set -euo pipefail

TARGET_FLAKE=""
TARGET_HOST=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --target-flake)
            TARGET_FLAKE="$2"
            shift 2
            ;;
        --target-host)
            TARGET_HOST="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET_FLAKE" || -z "$TARGET_HOST" ]]; then
    echo "Usage: $0 --target-flake <flake> --target-host <host>"
    exit 1
fi

nix run nixpkgs#nixos-rebuild switch -- \
    --flake "$TARGET_FLAKE" \
    --target-host "$TARGET_HOST" \
    --fast --use-remote-sudo
