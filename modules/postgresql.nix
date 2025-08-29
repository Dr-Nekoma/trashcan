{ pkgs, config, ... }:

let
  pg = pkgs.postgresql_17;
in
{
  environment.systemPackages = with pkgs; [
    barman
  ];

  # Postgres
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

      {
        name = "migrations";
        ensureClauses = {
          login = true;
          createrole = true;
        };
      }
    ];
    settings = {
      shared_preload_libraries = "pg_stat_statements";
      # pg_stat_statements config, nested attr sets need to be
      # converted to strings, otherwise postgresql.conf fails
      # to be generated.
      compute_query_id = "on";
      "pg_stat_statements.max" = 10000;
      "pg_stat_statements.track" = "all";
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

  # PG Bouncer
  # services.pgbouncer =
  #   let
  #     pgb_af_file_path = config.age.secrets.pgb_af.path;
  #   in
  #   {
  #     enable = true;
  #     poolMode = "transaction";
  #     defaultPoolSize = 50;
  #     listenAddress = "*";
  #     listenPort = 6432;
  #     authFile = pgb_af_file_path;
  #     databases = {
  #       lyceum = "host=localhost port=5432 dbname=lyceum user=lyceum";
  #     };
  #     extraConfig = ''
  #       min_pool_size=5
  #       max_client_conn=400
  #       reserve_pool_size=5
  #     '';
  #   };

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
  systemd.services.postgresql.postStart =
    let
      file = builtins.readFile config.age.secrets.pg_lyceum.path;
      json = builtins.toJSON file;
      users = builtins.catAttrs "users" json;
      pg_lyceum_user_secret = users.lyceum;
      pg_migratiton_user_secret = users.migrations;
    in
    ''
      psql -tA <<'EOF'
        DO $$
        DECLARE lyceum_password TEXT;
        DECLARE migrations_password TEXT;
        BEGIN
          lyceum_password := trim(both from replace(pg_read_file('${pg_lyceum_user_secret}'), E'\n', '''));
          EXECUTE format('ALTER USER lyceum WITH PASSWORD '''%s''';', lyceum_password);

          migrations_password := trim(both from replace(pg_read_file('${pg_migratiton_user_secret}'), E'\n', '''));
          EXECUTE format('ALTER USER migrations WITH PASSWORD '''%s''';', migrations_password);
        END $$;
      EOF
    '';
}
