{
  inputs = {
    agenix.url = "github:ryantm/agenix";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    impermanence.url = "github:nix-community/impermanence";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    lyceum = {
      url = "github:Dr-Nekoma/lyceum";
    };
  };

  outputs =
    inputs@{
      self,
      agenix,
      flake-parts,
      nixpkgs,
      disko,
      devenv,
      impermanence,
      lyceum,
      nixos-generators,
      treefmt-nix,
      ...
    }:
    let
      hostId = "41d2315f";

      bootstrapModules = [
        agenix.nixosModules.default
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./hosts/bootstrap/configuration.nix
      ];

      nekomaModules = [
        agenix.nixosModules.default
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./hosts/nekoma/configuration.nix
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, system, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          # This sets `pkgs` to a nixpkgs with allowUnfree option set.
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # nix build
          packages = {
            # ===============
            # Boostrap Images
            # ===============
            # ISO
            # nix build .#iso
            iso = nixos-generators.nixosGenerate {
              system = "x86_64-linux";
              modules = bootstrapModules;
              specialArgs = {
                hostId = hostId;
                profile = "ext4";
                target = "vm";
              };
              format = "iso";
            };

            # QEMU
            # nix build .#qemu
            qemu = nixos-generators.nixosGenerate {
              system = "x86_64-linux";
              modules = bootstrapModules;
              specialArgs = {
                hostId = hostId;
                profile = "ext4";
                target = "vm";
              };
              format = "qcow";
            };
          };

          # nix run
          apps = {
            # https://github.com/nix-community/disko/blob/a5c4f2ab72e3d1ab43e3e65aa421c6f2bd2e12a1/docs/disko-images.md#test-the-image-inside-a-vm
            # nix run .#qemu
            qemu = {
              type = "app";

              program = "${pkgs.writeShellScript "run-vm.sh" ''
                if [ -z "$1" ]; then
                  echo "Usage: $0 <path-to-boot-image>"
                  exit 1
                fi

                export NIX_DISK_IMAGE=$(mktemp -u -t nixos.XXXXXX.qcow2)

                trap "rm -f $NIX_DISK_IMAGE" EXIT
                cp "$1" "$NIX_DISK_IMAGE"
                ${pkgs.qemu}/bin/qemu-system-x86_64 \
                  -enable-kvm \
                  -m 2G \
                  -cpu max \
                  -smp 2 \
                  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                  -device virtio-net-pci,netdev=net0 \
                  -drive "if=virtio,format=raw,file=$NIX_DISK_IMAGE"
              ''}";
            };
          };

          # nix develop
          devShells = {
            # `nix develop .#ci`
            # reduce the number of packages to the bare minimum needed for CI
            ci = pkgs.mkShell {
              buildInputs = with pkgs; [
                just
              ];
            };

            # nix develop --impure
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                (
                  { pkgs, lib, ... }:
                  {
                    packages = with pkgs; [
                      age
                      agenix.packages.${system}.default
                      awscli2
                      bash
                      just
                    ];

                    scripts = {
                      apply.exec = "just apply";
                      bq.exec = "just bq";
                      rq.exec = "just rq";
                      destroy.exec = "just destroy";
                      init.exec = "just init";
                      plan.exec = "just plan";
                    };

                    languages.opentofu = {
                      enable = true;
                    };

                    enterShell = ''
                      Adding the Magalu CLI to $PATH
                      export PATH="$(pwd)/mg_cli:$PATH"
                    '';
                  }
                )
              ];
            };
          };

          # nix fmt
          formatter = treefmtEval.config.build.wrapper;
        };

      flake = {
        nixosConfigurations = {
          # -------
          #   AWS
          # -------
          # sudo nixos-rebuild boot --flake .#bootstrap_aws
          bootstrap_aws = nixpkgs.lib.nixosSystem {
            modules = bootstrapModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "aws";
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma_aws
          nekoma_aws = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "aws";
            };
          };

          # -------
          #   MGC
          # -------
          # sudo nixos-rebuild boot --flake .#bootstrap_mgc
          bootstrap_mgc = nixpkgs.lib.nixosSystem {
            modules = bootstrapModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "mgc";
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma_mgc
          nekoma_mgc = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "mgc";
            };
          };

          # --------
          #   QEMU
          # --------
          # sudo nixos-rebuild boot --flake .#bootstrap_vm
          bootstrap_vm = nixpkgs.lib.nixosSystem {
            modules = bootstrapModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "vm";
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma_vm
          nekoma_vm = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "vm";
            };
          };
        };
      };

    };
}
