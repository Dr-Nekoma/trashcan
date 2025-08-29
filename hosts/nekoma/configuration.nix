{
  lib,
  config,
  isImageTarget,
  ...
}:
let
  requiredModules = [
    ../../modules
    ../../users
  ];
  optionalModules = lib.optionals (!isImageTarget) [
    ./hardware-configuration.nix
  ];
in
{
  imports = requiredModules ++ optionalModules;

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # From the NixOS docs:
  # You should try to make this ID unique among your machines.
  # You can generate a random 32-bit ID using the following commands:
  # head -c 8 /etc/machine-id
  #
  # (this derives it from the machine-id that systemd generates) or
  #
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "41d2315f";

  modules.common = {
    enable = true;
  };

  modules.disko = {
    enable = true;
    profile = "vm";
  };

  # ZFS
  # boot = {
  #   supportedFilesystems = [ "zfs" ];
  #   zfs = {
  #     forceImportRoot = false;
  #   };
  # };

  # modules.impermanence = {
  #   enable = true;
  #   withSecrets = false;
  # };

  # age = {
  #   identityPaths = [
  #     "/nix/persist/etc/ssh/ssh_host_ed25519_key"
  #     "/nix/persist/etc/ssh/ssh_host_rsa_key"
  #   ];
  #   secrets = {
  #     pg_lyceum = {
  #       file = ../../secrets/pg_lyceum.age;
  #       owner = "postgres";
  #       group = "postgres";
  #       mode = "0440";
  #     };
  #   };
  # };
}
