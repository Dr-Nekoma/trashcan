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
      bootstrapArgs = {
        hostId = "41d2315f";
        profile = "vm";
      };

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
              specialArgs = bootstrapArgs;
              format = "iso";
            };

            # QEMU
            # nix build .#qemu
            qemu = nixos-generators.nixosGenerate {
              system = "x86_64-linux";
              modules = bootstrapModules;
              specialArgs = bootstrapArgs;
              format = "qcow";
            };
          };

          # nix run
          apps = {
            # nix run .#qemu
            qemu = {
              type = "app";

              program = "${pkgs.writeShellScript "run-vm.sh" ''
                export NIX_DISK_IMAGE=$(mktemp -u -t nixos.XXXXXX.qcow2)

                trap "rm -f $NIX_DISK_IMAGE" EXIT

                cp ${self.packages.x86_64-linux.qemu}/nixos.qcow2 $NIX_DISK_IMAGE
                chmod u+w $NIX_DISK_IMAGE

                ${pkgs.qemu}/bin/qemu-system-x86_64 \
                  -drive file=$NIX_DISK_IMAGE,if=virtio \
                  -m 2048 \
                  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                  -device virtio-net-pci,netdev=net0 \
                  -enable-kvm
              ''}";
            };
          };

          # nix develop
          devShells = {
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

                    languages.opentofu = {
                      enable = true;
                    };

                    enterShell = ''
                      Adding mg_cli to $PATH
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
          # AWS
          # sudo nixos-rebuild boot --flake .#bootstrap
          bootstrap = nixpkgs.lib.nixosSystem {
            modules = bootstrapModules;
            specialArgs = {
              hostId = bootstrapArgs.hostId;
              profile = "aws";
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma
          nekoma = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = bootstrapArgs.hostId;
              profile = "aws";
            };
          };

          # QEMU
          # sudo nixos-rebuild boot --flake .#bootstrap_vm
          bootstrap_vm = nixpkgs.lib.nixosSystem {
            modules = bootstrapModules;
            specialArgs = bootstrapArgs;
          };

          # sudo nixos-rebuild boot --flake .#nekoma_vm
          nekoma_vm = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = bootstrapArgs;
          };
        };
      };

    };
}
