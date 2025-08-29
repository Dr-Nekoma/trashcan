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
      nixos-generators,
      treefmt-nix,
      ...
    }:
    let
      hostModules = host: [
        agenix.nixosModules.default
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        host
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
            iso = nixos-generators.nixosGenerate {
              system = "x86_64-linux";
              modules = hostModules ./hosts/nekoma/configuration.nix;
              specialArgs = {
                isImageTarget = true;
              };
              format = "iso";
            };

            qemu = nixos-generators.nixosGenerate {
              system = "x86_64-linux";
              modules = hostModules ./hosts/nekoma/configuration.nix;
              specialArgs = {
                isImageTarget = true;
              };
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
            # `nix develop --impure`
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                (
                  { pkgs, lib, ... }:
                  {
                    packages = with pkgs; [
                      age
                      agenix.packages.${system}.default
                      bash
                      just
                    ];

                    languages.opentofu = {
                      enable = true;
                    };
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
          bootstrap = nixpkgs.lib.nixosSystem {
            modules = hostModules ./hosts/nekoma/configuration.nix;
            specialArgs = {
              isImageTarget = false;
            };
          };
        };
      };

    };
}
