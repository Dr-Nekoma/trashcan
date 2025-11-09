set dotenv-load := true
set export := true

target_vm := env_var_or_default("TARGET_VM", "bootstrap")
target_vm_memory := env_var_or_default("TARGET_VM_MEM", "2048")
target_flake := env_var_or_default("TARGET_FLAKE", "bootstrap")
hosts_dir := justfile_directory() / "hosts"
keys_dir := justfile_directory() / "keys"
modules_dir := justfile_directory() / "modules"
tofu_dir := justfile_directory() / "tofu"
secrets_dir := justfile_directory() / "secrets"
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
[group('nix')]
build:
    nix build ".#nixosConfigurations.{{ target_vm }}.config.system.build.toplevel"

# Builds a custom ISO with the bootstrap configuration
[group('nix')]
build-iso:
    nix build ".#iso"

# Builds the QEMU VM
[group('nix')]
build-qemu:
    nix build ".#nixosConfigurations.{{ target_vm }}_vm.config.system.build.vmWithDisko"

# Boot a QEMU VM, pointing to TARGET_VM
[group('nix')]
run-qemu: build-qemu
    nix run -L ".#nixosConfigurations.{{ target_vm }}_vm.config.system.build.vmWithDisko"

# Loads the current Flake into a REPL
[group('nix')]
repl:
    nix repl "#nixosConfigurations.{{ target_flake }}"

# ----------------------------
# Age-related Commands
# ----------------------------

# Resets the agenix file
[group('age')]
rekey:
    cd {{ secrets_dir }} && nix run github:ryantm/agenix -- -r

# ----------------------------
# OpenTofu Commands
# ----------------------------

# Initializes the tofu dir
[group('tofu')]
init tf_target:
    cd "{{ tofu_dir }}/{{ tf_target }}" && tofu init

# Plan infra changes
[group('tofu')]
plan tf_target +VARS="":
    cd "{{ tofu_dir }}/{{ tf_target }}" && tofu plan -out tfplan {{ VARS }}

# Provision infra changes
[group('tofu')]
apply tf_target +VARS="":
    cd "{{ tofu_dir }}/{{ tf_target }}" && tofu apply "tfplan" {{ VARS }}

# Destroy infra
[group('tofu')]
destroy tf_target:
    cd "{{ tofu_dir }}/{{ tf_target }}" && tofu apply -destroy -auto-approve

# ----------------------------
# Deploy Commands
# ----------------------------

# Deploy a NixOS VM (On AWS)
[group('deploy')]
deploy-aws:
    @./deploy.sh \
        --target-flake "nekoma_aws" \
        --target-platform "aws"

# Deploy a NixOS VM (On Magalu Cloud)
[group('deploy')]
deploy-mgc:
    @./deploy.sh \
        --target-flake "nekoma_mgc" \
        --target-platform "mgc"

# Deploy a NixOS VM (locally on QEMU)
[group('deploy')]
deploy-qemu:
    @./deploy.sh \
        --target-flake "nekoma_vm" \
        --target-platform "vm"
