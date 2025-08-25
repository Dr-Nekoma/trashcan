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

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age = {
      sshKeyPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/nix/persist/var/lib/sops-nix/trashcan.txt";
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
