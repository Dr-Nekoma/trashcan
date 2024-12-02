{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";

    agenix.url = "github:ryantm/agenix";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      agenix,
      devenv,
      disko,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Modules
        bootstrap = [
          ./configuration.nix
          ./modules/extras.nix
          ./modules/networking.nix
          ./modules/users.nix
        ];

        cloud = [
          ./modules/erlang.nix
          ./modules/nginx.nix
          ./modules/postgres.nix
          ./modules/secrets.nix
        ] ++ bootstrap;

        # Qemu Setup
        machine = nixpkgs.lib.nixosSystem {
          system = builtins.replaceStrings [ "darwin" ] [ "linux" ] system;

          modules = [
            agenix.nixosModules.default
            ./modules/qemu.nix
            ./modules/erlang.nix
            ./modules/extras.nix
            ./modules/networking.nix
            ./modules/nginx.nix
            ./modules/users.nix
          ];

          specialArgs = {
            inherit pkgs inputs;
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
          # Remote NixOS VM
          nixosConfigurations = {
            # This config is used when in the Terraform provisioning, so
            # it contains the bare minimum for us to log in there with ssh
            bootstrap = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = bootstrap ++ [ disko.nixosModules.disko ];
              specialArgs = {
                inherit pkgs inputs;
              };
            };

            # After provisioning the infra with Terraform, we start to deploy
            # this configuration here.
            nekoma = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = cloud ++ [
                agenix.nixosModules.default
                disko.nixosModules.disko
              ];
              specialArgs = {
                inherit pkgs inputs;
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

                  languages.opentofu = {
                    enable = true;
                  };

                  scripts = {
                    build.exec = "just build";
                    run.exec = "just run";
                    deploy.exec = "just deploy";
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
