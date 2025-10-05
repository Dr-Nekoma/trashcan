#!/usr/bin/env bash

# https://stackoverflow.com/a/246128/4614840
ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
printf "\nSetting up MG CLI from %s" "$ROOT_DIR"

RELEASE_URL="https://github.com/MagaluCloud/mgccli/releases/download"
RELEASE_ARCH=${RELEASE_ARCH:-linux_amd64}

CLI_VERSION=${CLI_VERSION:-0.49.0}
CLI_URL="$RELEASE_URL/v$CLI_VERSION/mgccli_${CLI_VERSION}_${RELEASE_ARCH}.tar.gz"
CLI_PATH="$ROOT_DIR/mg_cli"

rm -rf "$CLI_PATH"
[[ ! -d $CLI_PATH ]] && mkdir -p "$CLI_PATH"

printf "\nDownloading MG CLI from %s AT %s...\n" "$CLI_URL" "$CLI_PATH"

curl -sL "$CLI_URL" | tar xvz -C "$CLI_PATH"
