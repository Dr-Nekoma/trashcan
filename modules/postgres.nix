{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    barman
  ];

  # Postgres
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      shared_preload_libraries = "pg_stat_statements";
      # pg_stat_statements config, nested attr sets need to be
      # converted to strings, otherwise postgresql.conf fails
      # to be generated.
      compute_query_id = "on";
      "pg_stat_statements.max" = 10000;
      "pg_stat_statements.track" = "all";
    };
    extraPlugins = with pkgs.postgresql_16.pkgs; [
      periods
      repmgr
    ];
    initialScript = pkgs.writeText "init-sql-script" ''
      CREATE EXTENSION pg_stat_statements;

      CREATE USER admin SUPERUSER;
      GRANT ALL PRIVILEGES ON DATABASE mmo to admin;
    '';
  };

  # PG Bouncer
  services.pgbouncer = {
    enable = true;
    databases = {
      mmo = "host=localhost port=5432 dbname=mmo auth_user=admin";
    };
    extraConfig = ''
      min_pool_size=5
      reserve_pool_size=5
      max_client_conn=400
    '';
    listenAddress = "*";
    listenPort = 6432;
  };

  # haproxy
  #services.haproxy = {
  #  enable = true;
  #};

  # keepalived
  services.keepalived = {
    enable = true;
  };
}
