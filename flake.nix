{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      devenv,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";

        machine = nixpkgs.lib.nixosSystem {
          system = builtins.replaceStrings [ "darwin" ] [ "linux" ] system;

          modules = [
            (import ./modules/qemu.nix)
            (import ./modules/misc.nix {pkgs = pkgs; })
            (import ./modules/erlang.nix {pkgs = pkgs; })
            (import ./modules/postgres.nix { pkgs = pkgs; })
          ];
        };

        program = imageName: pkgs.writeShellScript "run-vm.sh" ''
          export IMAGE_NAME="${imageName}.qcow2"
          export NIX_DISK_IMAGE=$(mktemp -u -t $IMAGE_NAME)

          trap "rm -f $NIX_DISK_IMAGE" EXIT

          ${machine.config.system.build.vm}/bin/run-nixos-vm
        '';
      in
      {
        # nix build
        packages = {
          inherit machine;
        };

        # nix run
        apps = {
          default = {
            type = "app";

            program = builtins.toString (program "nixos");
          };
        };

        devShells = {
          # `nix develop --impure`
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              (
                { pkgs, lib, ... }:
                {
                  packages = with pkgs; [
                    bash
                    just
                  ];

                  # looks for the .env by default additionaly, there is .filename
                  # if an arbitrary file is desired
                  dotenv.enable = true;
                }
              )
            ];
          };
        };

        # nix fmt
        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
