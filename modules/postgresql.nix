{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.postgresql;
  pg = pkgs.postgresql_18;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.postgresql = {
    enable = mkEnableOption "Enable/Disable custom PostgreSQL options";

    package = mkOption {
      default = pg;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = with pkgs; [
        barman
        liburing
      ];

      services.postgresql = {
        enable = true;
        package = pg;
        ensureDatabases = [
          "lyceum"
        ];
        ensureUsers = [
          {
            name = "admin";
            ensureClauses = {
              login = true;
              superuser = true;
              createrole = true;
            };
          }

          {
            name = "lyceum";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              createrole = true;
            };
          }

          {
            name = "lyceum_auth";
            ensureClauses = {
              login = true;
            };
          }

          {
            name = "application";
            ensureClauses = {
              login = true;
            };
          }

          {
            name = "migrations";
            ensureClauses = {
              login = true;
              superuser = true;
              createrole = true;
            };
          }

          {
            name = "mnesia";
            ensureClauses = {
              login = true;
            };
          }
        ];
        settings = {
          shared_preload_libraries = "pg_stat_statements";
          wal_level = "logical";
          # pg_stat_statements config, nested attr sets need to be
          # converted to strings, otherwise postgresql.conf fails
          # to be generated.
          compute_query_id = "on";
          "pg_stat_statements.max" = 10000;
          "pg_stat_statements.track" = "all";
          # Async/IO Setup
          io_method = "io_uring";
          # Adjust shared buffers
          shared_buffers = "1GB";
          # Increase work memory for large operations
          work_mem = "16MB";
          # Enable huge pages if available
          huge_pages = "try";
          # Adjust I/O concurrency settings
          effective_io_concurrency = 32;
          maintenance_io_concurrency = 32;
        };
        extensions = with pg.pkgs; [
          # omnigres
          periods
          repmgr
        ];
        initialScript = pkgs.writeText "init-sql-script" ''
          CREATE EXTENSION pg_stat_statements;
        '';
      };

      services.pgbouncer = {
        enable = true;

        settings = {

          databases = {
            lyceum = "host=localhost port=5432 dbname=lyceum user=lyceum";
          };

          pgbouncer = {
            default_pool_size = 25;
            listen_addr = "*";
            listen_port = 6432;
            max_client_conn = 300;
            max_db_connections = 20;
            min_pool_size = 5;
            pool_mode = "transaction";
            reserve_pool_size = 5;
          };
        };
      };

      # Make pgbouncer wait for postgresql to be fully configured
      systemd.services.pgbouncer = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
        # Add a small delay to ensure pg's postStart has completed
        serviceConfig = {
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 4";
        };
      };

      # haproxy
      #services.haproxy = {
      #  enable = true;
      #};

      services.keepalived = {
        enable = true;
      };
    })
  ]);
}
