{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.postgresql;
  secrets_module = config.modules.secrets;
  pg = pkgs.postgresql_18;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
in
{
  options.modules.postgresql = {
    enable = mkEnableOption "Enable/Disable custom PostgreSQL options";
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
            name = "lyceum";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              createrole = true;
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
          omnigres
          periods
          repmgr
        ];
        initialScript = pkgs.writeText "init-sql-script" ''
          CREATE EXTENSION pg_stat_statements;
        '';
      };
    })

    (mkIf secrets_module.enable {
      # PG Bouncer
      #services.pgbouncer =
      #  let
      #    pgb_af_file_path = config.age.secrets.pgb_af.path;
      #  in
      #  {
      #    enable = true;
      #    poolMode = "transaction";
      #    defaultPoolSize = 50;
      #    listenAddress = "*";
      #    listenPort = 6432;
      #    authFile = pgb_af_file_path;
      #    databases = {
      #      lyceum = "host=localhost port=5432 dbname=lyceum user=lyceum";
      #    };
      #    extraConfig = ''
      #      min_pool_size=5
      #      max_client_conn=400
      #      reserve_pool_size=5
      #    '';
      #  };

      # haproxy
      #services.haproxy = {
      #  enable = true;
      #};

      # keepalived
      services.keepalived = {
        enable = true;
      };

      # Add passsword after pg starts
      # https://discourse.nixos.org/t/assign-password-to-postgres-user-declaratively/9726/3
      # systemd.services.postgresql.postStart =
      #   let
      #     pg_lyceum_user = config.age.secrets.pg_user_lyceum.path;
      #     pg_migratiton_user = config.age.secrets.pg_user_migrations.path;
      #   in
      #   ''
      #     psql -tA <<'EOF'
      #       DO $$
      #       DECLARE lyceum_password TEXT;
      #       DECLARE migrations_password TEXT;
      #       BEGIN
      #         lyceum_password := trim(both from replace(pg_read_file('${pg_lyceum_user}'), E'\n', '''));
      #         EXECUTE format('ALTER USER lyceum WITH PASSWORD '''%s''';', lyceum_password);
      #
      #         migrations_password := trim(both from replace(pg_read_file('${pg_migratiton_user}'), E'\n', '''));
      #         EXECUTE format('ALTER USER migrations WITH PASSWORD '''%s''';', migrations_password);
      #       END $$;
      #     EOF
      #   '';
    })
  ]);
}
