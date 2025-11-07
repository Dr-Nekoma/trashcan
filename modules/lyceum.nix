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
    if args ? lyceum then
      args.lyceum.packages.${pkgs.system}.server
    else
      throw "The 'lyceum' flake input must be passed via specialArgs to use the lyceum module";

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
      environment.systemPackages = [
        lyceum_server
      ];

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

        # Ensure dependencies and outputs are met
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "postgresql.service"
          "postgresql-setup.service"
          "run-agenix.d.mount"
        ];
        wants = [
          "postgresql.service"
          "run-agenix.d.mount"
        ];
        requires = [
          "postgresql.service"
          "run-agenix.d.mount"
        ];
        # Still unsure wether to go with PartsOf or BindsTo
        # https://stackoverflow.com/a/47216959/4614840
        # https://unix.stackexchange.com/a/327006/117072
        # partOf = [
        #   "postgresql.service"
        # ];

        # To make sure the packages in the service's $PATH
        path = with pkgs; [
          coreutils
          gnugrep
          gawk
          liburing
          openssl
        ];

        serviceConfig = {
          Type = "forking";
          User = cfg.user;
          Group = "users";
          ExecStart = "${lyceum_server}/bin/lyceum foreground";
          ExecStop = "${lyceum_server}/bin/lyceum stop";
          ExecRestart = "${lyceum_server}/bin/lyceum restart";

          # Restart configuration
          Restart = "on-failure";
          RestartSec = "10s";
          KillMode = "process";

          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          # ProtectSystem = "strict";
          ProtectHome = "read-only";

          # Allow writing to runtime directory
          RuntimeDirectory = "lyceum";
          RuntimeDirectoryMode = "0755";

          # Logs
          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = "lyceum";

          # Resource limits
          LimitNOFILE = "65536";
          LimitNPROC = "4096";

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
