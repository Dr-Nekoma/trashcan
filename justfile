set export := true

source := justfile_directory() + "/src"
tests := justfile_directory() + "/tests"
release := `git tag -l --sort=-creatordate | head -n 1`
replace := if os() == "linux" { "sed -i" } else { "sed -i '' -e" }

# For lazy people
alias r := run
alias r0 := run-n0
alias r1 := run-n1

# Lists all availiable targets
default:
    just --list

run node="default":
    nix run .#{{node}}

run-n0:
    nix run .#node00

run-n1:
    nix run .#node01
