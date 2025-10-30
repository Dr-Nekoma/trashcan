{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.lyceum;
  impermanence_module = config.modules.impermanence;
  secrets_module = config.modules.secrets;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.lyceum = {
    enable = mkEnableOption "Enable Lyceum's backend";

    user = mkOption {
      type = lib.types.str;
      default = "deploy";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      networking = {
        # I don't like it, but we need to fix the game
        # before disabling this.
        # https://github.com/Dr-Nekoma/lyceum/issues/66
        firewall = {
          allowedTCPPorts = [ 4369 ];
          allowedUDPPorts = [ 4369 ];
        };
      };
    })

    (mkIf secrets_module.enable {
      age = {
        secrets = {
          lyceum_erlang_cookie = {
            file = ../secrets/lyceum_erlang_cookie.age;
            # TODO: use the deploy user
            # owner = config.systemd.services.postgresql.serviceConfig.User;
            # group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "444";
          };
        };
      };

      systemd.services.erlang-cookie-setup = {
        description = "Setup an Erlang Node Cookie";
        wantedBy = [ "multi-user.target" ];

        # Run after agenix secrets are available
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;

          # Needs root to write to an user's home directory
          User = "root";
        };

        script =
          let
            homeDir =
              if impermanence_module.enable then
                "${impermanence_module.directory}/home/${cfg.user}"
              else
                "/home/${cfg.user}";
            cookieFile = "${homeDir}/.erlang.cookie";
          in
          ''
            # Ensure the home directory exists
            if [ ! -d "${homeDir}" ]; then
              echo "Home directory ${homeDir} does not exist"
              exit 1
            fi

            cat ${config.age.secrets.erlang_cookie.path} > ${cookieFile}

            echo "Erlang cookie installed at: ${cookieFile}"
          '';
      };
    })
  ]);
}
