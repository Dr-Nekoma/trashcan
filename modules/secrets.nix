{
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.secrets;
  impermanence_module = config.modules.impermanence;
in
{
  options.modules.secrets = {
    enable = mkEnableOption "Enable/Disable Agenix Secrets";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Agenix setup
      age = {
        identityPaths = [
          "/etc/ssh/server_key"
          "/etc/ssh/ssh_host_rsa_key"
        ];
        secrets = {
          pg_lyceum = {
            file = ../secrets/pg_lyceum.age;
            owner = "postgres";
            group = "postgres";
            mode = "0440";
          };

          server_ssh = {
            file = ../secrets/server_ssh.age;
          };
        };
      };
    })

    # If persistence is enabled
    (mkIf (impermanence_module.enable) {
      environment.persistence."${impermanence_module.directory}" = {
        directories = [
          "/etc/agenix"
        ];
      };

      age = {
        identityPaths = [
          "/etc/agenix/server_key"
        ];
      };
      virtualisation.vmVariantWithDisko.agenix.age.sshKeyPaths = [ "${impermanence_module.directory}/etc/agenix/server_key" ];
    })
    # Otherwise
    (mkIf (impermanence_module.enable) {
      age = {
        identityPaths = [
          "/etc/agenix/server_key"
        ];
      };
      virtualisation.vmVariantWithDisko.agenix.age.sshKeyPaths = [ "/etc/agenix/server_key" ];
    })
  ];
}
