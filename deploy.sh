#!/usr/bin/env bash

set -euo pipefail

TARGET_FLAKE=${TARGET_FLAKE:-"bootstrap"}
TARGET_PLATFORM=${TARGET_PLATFORM:-"aws"}
TARGET_HOST=""

DIR="$(pwd)/tofu/${TARGET_PLATFORM}/outputs"
OUT_FILE="$DIR/output.json"
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

if [[ -z "$TARGET_HOST" ]]; then
    if [[ -f "$OUT_FILE" ]]; then
        TARGET_HOST=$(jq --raw-output '.public_dns' "$OUT_FILE")
    else
        echo "Usage: $0 --target-flake <flake> --target-host <host>"
        exit 1
    fi
fi

printf "\n\tDEPLOYING FLAKE=%s to TARGET=%s...\n" "$TARGET_FLAKE" "$TARGET_HOST"

nix run nixpkgs#nixos-rebuild boot -- \
    --flake ".#$TARGET_FLAKE" \
    --target-host "root@$TARGET_HOST" \
    --verbose --fast --use-remote-sudo
