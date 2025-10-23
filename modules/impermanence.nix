# https://github.com/nix-community/impermanence#module-usage
{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.impermanence;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.impermanence = {
    enable = mkEnableOption "Enable the Impermanence module, for ephemeral state outside the Nix configuration";

    directory = mkOption {
      description = "The directory to use for the impermanence module.";
      default = "/persist";
      type = lib.types.str;
    };

    profile = mkOption {
      type = lib.types.str;
      default = null;
      description = "The profile to use for the module.";
    };

  };

  config = mkIf cfg.enable (mkMerge [
    ({
      # FS setup
      fileSystems."${cfg.directory}".neededForBoot = true;
      # Workaround for the following service failing with a bind mount for /etc/machine-id
      # see: https://github.com/nix-community/impermanence/issues/229
      # boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
      # systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
      environment.persistence."${cfg.directory}" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/etc/ssh"
          "/var/lib/nixos"
          "/var/lib/postgresql"
          "/var/lib/tailscale"
          "/var/lib/secrets"
          "/var/log"
        ];
        # Files to persist
        files = [
          "/etc/machine-id"
          "/var/lib/id_ed25519"
        ];
        users = {
          bene = {
            directories = [
              "Code"
              "Documents"
              {
                directory = ".gnupg";
                mode = "0700";
              }
              {
                directory = ".ssh";
                mode = "0700";
              }
            ];
            files = [
              ".zsh_history"
            ];
          };
        };
      };
    })

    (mkIf (cfg.profile == "vm") {
      # For testing purposes with a local VM
      virtualisation.vmVariantWithDisko.virtualisation.fileSystems."${cfg.directory}".neededForBoot =
        true;
    })
  ]);
}
