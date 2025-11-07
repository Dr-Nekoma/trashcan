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
        (import ./overlays)
      ];

      nekomaModules = [
        agenix.nixosModules.default
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./hosts/nekoma/configuration.nix
        (import ./overlays)
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
                set -e
                echo "Building VM with Disko..."
                ${pkgs.nix}/bin/nix build ".#nixosConfigurations.bootstrap_vm.config.system.build.vmWithDisko" "$@"

                export QEMU_KERNEL_PARAMS="console=ttyS0"
                export QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:4369-:4369,hostfwd=udp:127.0.0.1:4369-:4369"

                echo "Running VM..."
                ${pkgs.nix}/bin/nix run -L ".#nixosConfigurations.bootstrap_vm.config.system.build.vmWithDisko"
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
                      # TOFU commands
                      ## Init
                      ia.exec = "just init aws";
                      im.exec = "just init mgc";
                      ## Plan
                      pa.exec = "just plan aws";
                      pm.exec = "just plan mgc";
                      ## Apply
                      aa.exec = "just apply aws";
                      am.exec = "just apply mgc";
                      ## Destroy
                      da.exec = "just destroy aws";
                      dm.exec = "just destroy mgc";
                      # VM commands
                      bq.exec = "just bq";
                      rq.exec = "just rq";
                    };

                    languages.opentofu = {
                      enable = true;
                    };

                    enterShell = ''
                      echo "Adding the Magalu CLI to \$PATH"
                      export PATH="$(pwd)/mg_cli:$PATH"
                      # Some Extra QEMU envars that are useful when doing local testing
                      export QEMU_KERNEL_PARAMS="console=ttyS0"
                      # Options to foward 
                      #   host 2222 -> vm 22
                      export QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:4369-:4369,hostfwd=udp:127.0.0.1:4369-:4369"
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
              inherit lyceum;
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma_aws
          nekoma_aws = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "aws";
              inherit lyceum;
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
              inherit lyceum;
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma_mgc
          nekoma_mgc = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "mgc";
              inherit lyceum;
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
              inherit lyceum;
            };
          };

          # sudo nixos-rebuild boot --flake .#nekoma_vm
          nekoma_vm = nixpkgs.lib.nixosSystem {
            modules = nekomaModules;
            specialArgs = {
              hostId = hostId;
              profile = "ext4";
              target = "vm";
              inherit lyceum;
            };
          };
        };
      };

    };
}
