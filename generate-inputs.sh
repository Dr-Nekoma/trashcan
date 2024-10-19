#!/usr/bin/env bash

set -euo pipefail

REGION=""
FLAKE=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --flake)
            FLAKE="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$FLAKE" || -z "$REGION" ]]; then
    echo "Usage: $0 --flake <flake> --region <region>"
    exit 1
fi

tee "$(pwd)/inputs.tfvars" <<EOF
region = "${REGION}"
flake = "${FLAKE}"
EOF
