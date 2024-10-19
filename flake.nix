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
            ./modules/qemu.nix
            ./modules/caddy.nix
            ./modules/erlang.nix
            ./modules/extras.nix
            ./modules/postgres.nix
            ./modules/users.nix
          ];

          specialArgs = {
            inherit pkgs;
          };
        };

        program =
          imageName:
          pkgs.writeShellScript "run-vm.sh" ''
            export IMAGE_NAME="${imageName}.qcow2"
            export NIX_DISK_IMAGE=$(mktemp -u -t $IMAGE_NAME)

            trap "rm -f $NIX_DISK_IMAGE" EXIT

            ${machine.config.system.build.vm}/bin/run-nixos-vm
          '';
      in
      {
        # nix build
        packages = {
          # Remote NixOS AWS VM
          nixosConfigurations = {
            kanagawa = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                ./configuration.nix
                ./modules/caddy.nix
                ./modules/erlang.nix
                ./modules/extras.nix
                ./modules/postgres.nix
                ./modules/users.nix
              ];
              specialArgs = {
                inherit pkgs;
              };
            };
          };
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

                  scripts = {
                    build.exec = "just build";
                    run.exec = "just run";
                  };

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
