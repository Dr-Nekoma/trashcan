{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    barman
  ];

  # Postgres
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
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
      # pg_stat_statements config, nested attr sets need to be
      # converted to strings, otherwise postgresql.conf fails
      # to be generated.
      compute_query_id = "on";
      "pg_stat_statements.max" = 10000;
      "pg_stat_statements.track" = "all";
    };
    extensions = with pkgs.postgresql_17.pkgs; [
      periods
      #repmgr
    ];
    initialScript = pkgs.writeText "init-sql-script" ''
      CREATE EXTENSION pg_stat_statements;
    '';
  };

  # PG Bouncer
  #services.pgbouncer = 
  #  let
  #    pgb_af_file_path = config.age.secrets.pgb_af.path;
  #  in
  #  {
  #    enable = true;
  #    settings = {
  #      auth_file = pgb_af_file_path;
  #      databases = {
  #        lyceum = "host=localhost port=5432 dbname=lyceum user=lyceum";
  #      };
  #      default_pool_size = 50;
  #      listen_addr = "*";
  #      listen_port = 6432;
  #      min_pool_size=5;
  #      max_client_conn=400;
  #      pool_mode = "transaction";
  #      reserve_pool_size=5;
  #    };
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
  systemd.services.postgresql.postStart = 
    let
      password_file_path = config.age.secrets.pg_mp.path;
    in ''
    $PSQL -tA <<'EOF'
      DO $$
      DECLARE password TEXT;
      BEGIN
        password := trim(both from replace(pg_read_file('${password_file_path}'), E'\n', '''));
        EXECUTE format('ALTER USER lyceum WITH PASSWORD '''%s''';', password);
      END $$;
    EOF
  '';
}
