{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.secrets;
  disko_module = config.modules.disko;
  impermanence_module = config.modules.impermanence;
  lyceum_module = config.modules.lyceum;
  postgresql_module = config.modules.postgresql;

  default_prefix = if impermanence_module.enable then impermanence_module.directory else "";
  lyceum_work_dir =
    if impermanence_module.enable then
      "${impermanence_module.directory}/home/${lyceum_module.user}"
    else
      "/home/${lyceum_module.user}";

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
        ]
        ++ cfg.paths;
      };
    })

    # Lyceum
    (mkIf lyceum_module.enable {
      age = {
        secrets = {
          lyceum_application_env = {
            file = ../secrets/lyceum_application_env.age;
            owner = lyceum_module.user;
            group = "users";
            mode = "440";
          };

          # lyceum_erlang_cookie = {
          #   file = ../secrets/lyceum_erlang_cookie.age;
          #   owner = lyceum_module.user;
          #   group = "users";
          #   mode = "440";
          #   path = "${lyceum_work_dir}/.erlang.cookie";
          # };
        };
      };

      # Make sure Lyceum's systemd service has the right envars
      systemd.services.lyceum = {
        serviceConfig = {
          EnvironmentFile = config.age.secrets.lyceum_application_env.path;
        };
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

          pg_user_lyceum_application = {
            file = ../secrets/pg_user_lyceum_application.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum_auth = {
            file = ../secrets/pg_user_lyceum_auth.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum_mnesia = {
            file = ../secrets/pg_user_lyceum_mnesia.age;
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

      # Add passswords after pg starts
      # https://discourse.nixos.org/t/assign-password-to-postgres-user-declaratively/9726/3
      systemd.services.postgresql = {
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/databases/postgresql.nix
        after = [
          "network.target"
          "run-agenix.d.mount"
        ];
        postStart =
          let
            pg_lyceum_user = config.age.secrets.pg_user_lyceum.path;
            pg_lyceum_application_user = config.age.secrets.pg_user_lyceum_application.path;
            pg_lyceum_auth_user = config.age.secrets.pg_user_lyceum_auth.path;
            pg_lyceum_mnesia_user = config.age.secrets.pg_user_lyceum_mnesia.path;
            pg_migration_user = config.age.secrets.pg_user_migrations.path;
          in
          ''
            check-connection() {
              psql -d postgres -v ON_ERROR_STOP=1 <<-'  EOF'
                SELECT pg_is_in_recovery() \gset
                \if :pg_is_in_recovery
                \i still-recovering
                \endif
              EOF
            }

            sleep 1
            # Wait for PostgreSQL to be fully ready
            while ! check-connection 2> /dev/null; do
                if ! systemctl is-active --quiet postgresql.service; then exit 1; fi
                sleep 0.5
            done

            ${postgresql_module.package}/bin/psql -tA <<'EOF'
              DO $$
              DECLARE lyceum_password TEXT;
              DECLARE lyceum_app_password TEXT;
              DECLARE lyceum_auth_password TEXT;
              DECLARE lyceum_mnesia_password TEXT;
              DECLARE migrations_password TEXT;
              BEGIN
                -- Read and set lyceum password
                lyceum_password := trim(both from replace(pg_read_file('${pg_lyceum_user}'), E'\n', '''));
                EXECUTE format('ALTER USER lyceum WITH PASSWORD %L;', lyceum_password);

                -- Read and set migrations password
                migrations_password := trim(both from replace(pg_read_file('${pg_migration_user}'), E'\n', '''));
                EXECUTE format('ALTER USER migrations WITH PASSWORD %L;', migrations_password);

                -- Application User
                lyceum_app_password := trim(both from replace(pg_read_file('${pg_lyceum_application_user}'), E'\n', '''));
                EXECUTE format('ALTER USER application WITH PASSWORD %L;', lyceum_app_password);

                -- Auth User
                lyceum_auth_password := trim(both from replace(pg_read_file('${pg_lyceum_auth_user}'), E'\n', '''));
                EXECUTE format('ALTER USER lyceum_auth WITH PASSWORD %L;', lyceum_auth_password);

                -- MNESIA User
                lyceum_mnesia_password := trim(both from replace(pg_read_file('${pg_lyceum_mnesia_user}'), E'\n', '''));
                EXECUTE format('ALTER USER mnesia WITH PASSWORD %L;', lyceum_mnesia_password);

                -- Grant permissions to users
                GRANT CONNECT ON DATABASE lyceum TO migrations;
                GRANT CREATE ON DATABASE lyceum TO migrations;
                -- Grant default privileges for future schemas created by migrations user
                ALTER DEFAULT PRIVILEGES FOR ROLE migrations GRANT ALL ON TABLES TO migrations;
                ALTER DEFAULT PRIVILEGES FOR ROLE migrations GRANT ALL ON SEQUENCES TO migrations;

                GRANT CONNECT ON DATABASE lyceum TO application;
                GRANT CONNECT ON DATABASE lyceum TO lyceum_auth;
                GRANT CONNECT ON DATABASE lyceum TO mnesia;
              END $$;
            EOF
          '';
      };

      services.pgbouncer.settings = {
        pgbouncer = {
          auth_file = config.age.secrets.pg_bouncer_auth_file.path;
        };
      };

    })
  ]);
}
