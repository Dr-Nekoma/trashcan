{
  lib,
  config,
  ...
}:

let
  cfg = config.modules.secrets;
  disko_module = config.modules.disko;
  impermanence_module = config.modules.impermanence;
  postgresql_module = config.modules.postgresql;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.secrets = {
    enable = mkEnableOption "Enable/Disable Agenix Secrets";

    paths = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
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
    (mkIf (impermanence_module.enable) (mkMerge [
      {
        # Age
        age = {
          # Private key of the SSH key pair. This is the other pair of what was supplied
          # in `secrets.nix`.
          #
          # This tells `agenix` where to look for the private key.
          identityPaths = [
            "${impermanence_module.directory}/etc/ssh/id_ed25519"
            "${impermanence_module.directory}/etc/ssh/ssh_host_ed25519_key"
            "${impermanence_module.directory}/etc/ssh/ssh_host_rsa_key"
          ]
          ++ (map (x: "${impermanence_module.directory}${x}") cfg.paths);
        };

        # Agenix Keys
        environment.persistence."${impermanence_module.directory}" = {
          directories = [
            "/etc/agenix"
          ];
        };
      }
    ]))
    # Otherwise (impermanence being disabled)
    (mkIf (!impermanence_module.enable) {
      # Age
      age = {
        identityPaths = [
          "/etc/ssh/id_ed25519"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_rsa_key"
        ]
        ++ cfg.paths;
      };
    })
  ]);
}
