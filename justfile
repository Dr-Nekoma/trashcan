set dotenv-load
set export := true

hosts_dir := justfile_directory() + "/hosts"
keys_dir := justfile_directory() + "/keys"
modules_dir := justfile_directory() + "/modules"
tofu_dir := justfile_directory() + "/tofu"

target_vm := env_var_or_default("TARGET_VM", "bootstrap")

release := `git tag -l --sort=-creatordate | head -n 1`
replace := if os() == "linux" { "sed -i" } else { "sed -i '' -e" }

# For lazy people
alias bi := build-iso
alias bq := build-qemu

# Lists all availiable targets
default:
    just --list

# ----------------------------
# Nix Commands
# ----------------------------
# Default Build, uses `nixosConfiguration`
build:
    nix build ".#nixosConfigurations.{{target_vm}}.config.system.build.toplevel"

build-iso:
    nix build ".#iso"

build-qemu:
    nix build ".#qemu"

# Loads the current Flake into a REPL
repl:
    nix repl {{target_flake}}

# Runs a Qemu VM, to quickly test changes
run-qemu:
    nix run ".#qemu"

# ----------------------------
# Age-related Commands
# ----------------------------
rekey:
    cd secrets && nix run github:ryantm/agenix -- -r

# ----------------------------
# OpenTofu Commands
# ----------------------------
