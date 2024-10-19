set dotenv-load
set export := true

target_vm := env_var_or_default("TARGET_VM", "nekoma")
target_host := env_var_or_default("TARGET_HOST", "localhost")
target_flake := ".#" + target_vm
modules := justfile_directory() + "/module"
release := `git tag -l --sort=-creatordate | head -n 1`
replace := if os() == "linux" { "sed -i" } else { "sed -i '' -e" }

# For lazy people
alias r := run

# Lists all availiable targets
default:
    @echo "Setting TARGET_FLAKE={{ target_flake }}"
    just --list

# Builds the remote AWS EC2 VM
build:
    nix build .#nixosConfigurations.{{target_flake}}.config.system.build.toplevel

# Deploys the VM to EC2
deploy:
    @./deploy.sh --target-flake {{ target_flake }} --target-host {{ target_host }}

# Loads the current Flake into a REPL
repl:
    nix repl .#nixosConfigurations.{{target_flake}}

# Runs a Qemu VM, to quickly test changes
run:
    nix run
