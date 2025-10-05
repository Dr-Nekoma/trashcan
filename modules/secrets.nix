{
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.secrets;
  disko_module = config.modules.disko;
  impermanence_module = config.modules.impermanence;
  postgresql_module = config.modules.postgresql;
in
{
  options.modules.secrets = {
    enable = mkEnableOption "Enable/Disable Agenix Secrets";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      # Agenix setup
      age = {
        secrets = {
          server_ssh = {
            file = ../secrets/server_ssh.age;
            path = "/etc/agenix/server_ssh";
          };
        };
      };

      # SSH
      services.openssh = {
        hostKeys = [
          {
            type = "ed25519";
            path = config.age.secrets.server_ssh.path;
          }
        ];
      };
    })

    # Impermance-based configs
    # https://discourse.nixos.org/t/how-to-define-actual-ssh-host-keys-not-generate-new/31775/8
    # If persistence is enabled
    (mkIf (impermanence_module.enable) {
      # Age
      age = {
        identityPaths = [
          "${impermanence_module.directory}/etc/agenix/server_key"
        ];
      };
      virtualisation.vmVariantWithDisko.agenix.age.sshKeyPaths = [
        "${impermanence_module.directory}/etc/agenix/server_key"
      ];

      # Agenix Keys
      environment.persistence."${impermanence_module.directory}" = {
        directories = [
          "/etc/agenix"
        ];
      };
    })
    # Otherwise (with AWS)
    (mkIf (!impermanence_module.enable && disko_module.profile == "aws") {
      # Age
      age = {
        identityPaths = [
          "/etc/agenix/server_ssh"
          "/var/lib/secrets/id_ed25519"
        ];
      };

      # SSH
      services.openssh = {
        hostKeys = [
          {
            type = "ed25519";
            path = "/var/lib/secrets/id_ed25519";
          }
        ];
      };
    })

    # If the PostgreSQL module is enabled as well
    (mkIf postgresql_module.enable {
      # Agenix setup
      age = {
        secrets = {
          pg_user_lyceum = {
            file = ../secrets/pg_user_lyceum.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
            path = "/etc/agenix/pg_user_lyceum";
          };

          pg_user_migrations = {
            file = ../secrets/pg_user_migrations.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
            path = "/etc/agenix/pg_user_migrations";
          };
        };
      };
    })

  ]);
}
