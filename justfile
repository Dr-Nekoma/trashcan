set dotenv-load := true
set export := true

hosts_dir := justfile_directory() + "/hosts"
keys_dir := justfile_directory() + "/keys"
modules_dir := justfile_directory() + "/modules"
tofu_dir := justfile_directory() + "/tofu/aws"
secrets_dir := justfile_directory() + "/secrets"
target_vm := env_var_or_default("TARGET_VM", "bootstrap")
target_vm_memory := env_var_or_default("TARGET_VM_MEM", "2048")
target_flake := env_var_or_default("TARGET_FLAKE", "bootstrap")
release := `git tag -l --sort=-creatordate | head -n 1`
replace := if os() == "linux" { "sed -i" } else { "sed -i '' -e" }

# For lazy people

alias bi := build-iso
alias bq := build-qemu
alias rq := run-qemu

# Lists all availiable targets
default:
    just --list

# ----------------------------
# Nix Commands
# ----------------------------

# Default Build, uses `nixosConfiguration`
build:
    nix build ".#nixosConfigurations.{{ target_vm }}.config.system.build.toplevel"

# Builds a custom ISO with the bootstrap configuration
build-iso:
    nix build ".#iso"

# Builds the QEMU VM
build-qemu:
    nix build ".#nixosConfigurations.{{ target_vm }}_vm.config.system.build.vmWithDisko"

# Loads the current Flake into a REPL
repl:
    nix repl "#nixosConfigurations.{{ target_flake }}"

# ----------------------------
# Age-related Commands
# ----------------------------

# Resets the agenix file
rekey:
    cd {{ secrets_dir }} && nix run github:ryantm/agenix -- -r

# ----------------------------
# OpenTofu Commands
# ----------------------------

# Initializes the tofu dir
init:
    cd {{ tofu_dir }} && tofu init

# Plan infra changes
plan:
    cd {{ tofu_dir }} && tofu plan -out tfplan

# Provision infra changes
apply:
    cd {{ tofu_dir }} && tofu apply "tfplan"

# Destroy infra
destroy:
    cd {{ tofu_dir }} && tofu apply -destroy -auto-approve

# ----------------------------
# VM Commands
# ----------------------------

# Boot a QEMU VM, pointing to TARGET_VM
run-qemu: build-qemu
    nix run -L '.#nixosConfigurations.{{ target_vm }}_vm.config.system.build.vmWithDisko'

# ----------------------------
# Deploy Commands
# ----------------------------

# Deploy a NixOS VM (On AWS)
deploy_aws:
    @./deploy.sh \
        --target-flake "nekoma_aws" \
        --target-platform "aws"

# Deploy a NixOS VM (On Magalu Cloud)
deploy_mgc:
    @./deploy.sh \
        --target-flake "nekoma_mgc" \
        --target-platform "mgc"
