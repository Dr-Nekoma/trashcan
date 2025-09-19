#!/usr/bin/env bash

set -euo pipefail

TARGET_FLAKE="bootstrap"
TARGET_HOST=""

DIR="$(pwd)/tofu/aws/outputs"
OUT_FILE="$DIR/output.json"

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

if [[ -z "$TARGET_HOST" ]]; then
    if [[ -f "$OUT_FILE" ]]; then
        TARGET_HOST=$(jq --raw-output '.public_dns' "$OUT_FILE")
    else
        echo "Usage: $0 --target-flake <flake> --target-host <host>"
        exit 1
    fi
fi

echo "DEPLOYING FLAKE=$TARGET_FLAKE to TARGET=$TARGET_HOST"

nix run nixpkgs#nixos-rebuild boot -- \
    --flake ".#$TARGET_FLAKE" \
    --target-host "root@nixos" \
    --fast --use-remote-sudo
