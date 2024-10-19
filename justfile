set dotenv-load
set export := true

target_region := env_var_or_default("TARGET_REGION", "us-east-1")
target_vm := env_var_or_default("TARGET_VM", "nekoma")
target_host := env_var_or_default("TARGET_HOST", "localhost")
target_flake := ".#nixosConfigurations." + target_vm

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
    nix build {{target_flake}}.config.system.build.toplevel

# Deploys the VM to EC2
deploy:
    @./deploy.sh --target-flake {{ target_flake }} --target-host {{ target_host }}

# Updates terraform variables
update-vars:
    @./generate-inputs.sh --flake ".#{{ target_vm }}" --region {{ target_region }}

# Runs `terraform plan`
plan:
    terraform plan -var-file="inputs.tfvars" -out tfplan

# Runs `terraform apply`
apply:
    terraform apply "tfplan"

# Destroys Terraform infra
destroy:
    terraform apply -destroy -var "flake=.#{{target_vm}}" -var "region={{target_region}}"

# Loads the current Flake into a REPL
repl:
    nix repl {{target_flake}}

# Runs a Qemu VM, to quickly test changes
run:
    nix run
