set export := true

modules := justfile_directory() + "/modules"
release := `git tag -l --sort=-creatordate | head -n 1`
replace := if os() == "linux" { "sed -i" } else { "sed -i '' -e" }

# For lazy people
alias r := run

# Lists all availiable targets
default:
    just --list

build:
    nix build

run:
    nix run
