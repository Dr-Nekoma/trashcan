{
  lib,
  config,
  isImageTarget,
  extraModules,
  sops,
  ...
}:
{
  imports =
    lib.optionals (!isImageTarget) [
      ./hardware-configuration.nix
      ./disko-config.nix
    ]
    ++ extraModules;

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "~/.config/sops/age/trashcan.txt";
  sops.secrets = {
    "postgresql/db_lyceum/user_lyceum" = {
      owner = "postgres";
      group = "postgres";
    };

    "postgresql/db_lyceum/user_migrations" = {
      owner = "postgres";
      group = "postgres";
    };
  };
}
