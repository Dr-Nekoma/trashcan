{
  lib,
  config,
  isImageTarget,
  extraModules ? [ ],
  ...
}:
let
  requiredModules = [
    ./persist.nix
  ];
  optionalModules = lib.optionals (!isImageTarget) [
    ./disko-config.nix
    ./hardware-configuration.nix
  ];
in
{
  imports = requiredModules ++ optionalModules ++ extraModules;

  # sops-nix executes secretsForUsers before impermanence module activation,
  # leading to incorrect user password provision on startup.
  # To fix this behaviour, host keys can be simply moved to persistent directory explicitly.
  # config.services.openssh.hostKeys = [
  #   {
  #     bits = 4096;
  #     path = "${cfg.persistentDirectory}/etc/ssh/ssh_host_rsa_key";
  #     type = "rsa";
  #   }
  #   {
  #     path = "${cfg.persistentDirectory}/etc/ssh/ssh_host_ed25519_key";
  #     type = "ed25519";
  #   }
  # ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age = {
      # sshKeyPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/nix/persist/var/lib/sops-nix/age.key";
      generateKey = true;
    };

    secrets = {
      "postgresql/db_lyceum/user_lyceum" = {
        owner = "postgres";
        group = "postgres";
      };

      "postgresql/db_lyceum/user_migrations" = {
        owner = "postgres";
        group = "postgres";
      };
    };
  };
}
