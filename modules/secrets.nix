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

  default_prefix = if impermanence_module.enable then impermanence_module.directory else "";

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
      age = {
        # Private key of the SSH key pair. This is the other pair of what was supplied
        # in `secrets.nix`.
        #
        # This tells `agenix` where to look for the private key.
        identityPaths = [
          "${default_prefix}/var/lib/agenix/id_ed25519"
        ];
      };
    })

    # PostgreSQL
    (mkIf (postgresql_module.enable) {
      age = {
        secrets = {
          pg_bouncer_auth_file = {
            file = ../secrets/pg_bouncer_auth_file.age;
            owner = config.systemd.services.pgbouncer.serviceConfig.User;
            group = config.systemd.services.pgbouncer.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum = {
            file = ../secrets/pg_user_lyceum.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_migrations = {
            file = ../secrets/pg_user_migrations.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };
        };
      };

      services.pgbouncer.settings = {
        pgbouncer = {
          auth_file = config.age.secrets.pg_bouncer_auth_file.path;
        };
      };

      # Add passsword after pg starts
      # https://discourse.nixos.org/t/assign-password-to-postgres-user-declaratively/9726/3
      systemd.services.postgresql.postStart =
        let
          pg_lyceum_user = config.age.secrets.pg_user_lyceum.path;
          pg_migratiton_user = config.age.secrets.pg_user_migrations.path;
        in
        ''
          psql -tA <<'EOF'
            DO $$
            DECLARE lyceum_password TEXT;
            DECLARE migrations_password TEXT;
            BEGIN
              lyceum_password := trim(both from replace(pg_read_file('${pg_lyceum_user}'), E'\n', '''));
              EXECUTE format('ALTER USER lyceum WITH PASSWORD '''%s''';', lyceum_password);

              migrations_password := trim(both from replace(pg_read_file('${pg_migratiton_user}'), E'\n', '''));

              CREATE USER migrations
              WITH LOGIN SUPERUSER CREATEROLE PASSWORD 'migrations';
              GRANT CONNECT ON DATABASE lyceum TO migrations;
              GRANT CREATE ON DATABASE lyceum TO migrations;

              -- Grant default privileges for future schemas created by migrations user
              ALTER DEFAULT PRIVILEGES FOR ROLE migrations GRANT ALL ON TABLES TO migrations;
              ALTER DEFAULT PRIVILEGES FOR ROLE migrations GRANT ALL ON SEQUENCES TO migrations;

              EXECUTE format('ALTER USER migrations WITH PASSWORD '''%s''';', migrations_password);
            END $$;
          EOF
        '';
    })
  ]);
}
