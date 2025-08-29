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
    withSecrets = mkEnableOption "Enable/Disable support for Agenix";
    directory = mkOption {
      description = "The directory to use for the impermanence module.";
      default = "/persist";
      type = lib.types.str;
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # FS setup
      fileSystems."${cfg.directory}".neededForBoot = true;
      # For testing purposes with a local VM
      virtualisation.vmVariantWithDisko.virtualisation.fileSystems."${cfg.directory}".neededForBoot =
        true;
      # Files to persist
      environment.persistence."${cfg.directory}" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/var/lib/nixos"
          "/var/lib/postgresql"
          # "/var/lib/tailscale"
          "/var/log"
        ];
        files = [
          "/etc/machine-id"
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

      # Workaround for the following service failing with a bind mount for /etc/machine-id
      # see: https://github.com/nix-community/impermanence/issues/229
      # boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
      # systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    })
    (mkIf (cfg.withSecrets) {
      environment.persistence."${cfg.directory}" = {
        directories = [
          "/etc/agenix"
        ];
      };
      virtualisation.vmVariantWithDisko.agenix.age.sshKeyPaths = [ "/tmp/shared/sops_ed25519_key" ];
    })
  ];
}
