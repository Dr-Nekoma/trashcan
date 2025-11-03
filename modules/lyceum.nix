{
  lib,
  config,
  pkgs,
  ...
}@args:

let
  cfg = config.modules.lyceum;
  impermanence_module = config.modules.impermanence;

  # Get the lyceum server package from the flake input
  lyceum_server = 
    if args ? lyceum 
    then args.lyceum.packages.${pkgs.system}.server
    else throw "The 'lyceum' flake input must be passed via specialArgs to use the lyceum module";

  lyceum_work_dir =
    if impermanence_module.enable then
      "${impermanence_module.directory}/home/${cfg.user}"
    else
      "/home/${cfg.user}";

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

    epmd_port = mkOption {
      type = lib.types.port;
      default = 4369;
      description = "Erlang Port Mapper Daemon port";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = [ lyceum_server ];

      networking = {
        # I don't like it, but we need to fix the game's server
        # before disabling this.
        # https://github.com/Dr-Nekoma/lyceum/issues/66
        firewall = {
          allowedTCPPorts = [
            cfg.epmd_port
          ];
          allowedUDPPorts = [
            cfg.epmd_port
          ];
        };
      };

      # Systemd services
      systemd.services.lyceum = {
        description = "Lyceum Game Server";
        wantedBy = [ "multi-user.target" ];

        # Ensure dependencies are met
        after = [
          "network.target"
          "postgresql.service"
        ];
        wants = [
          "postgresql.service"
        ];
        requires = [
          "postgresql.service"
        ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = "users";

          # Path to the release
          ExecStart = "${lyceum_server}/bin/lyceum foreground";

          # Restart configuration
          Restart = "always";
          RestartSec = "10s";

          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";

          # Allow writing to runtime directory
          RuntimeDirectory = "lyceum";
          RuntimeDirectoryMode = "0755";

          # Logs
          StandardOutput = "journal";
          StandardError = "journal";

          # Resource limits
          LimitNOFILE = "65536";

          # Working directory
          WorkingDirectory = "${lyceum_work_dir}/Apps";
        };

        # Restart on failure with backoff
        unitConfig = {
          StartLimitBurst = 5;
          StartLimitIntervalSec = 60;
        };
      };
    })
  ]);
}
