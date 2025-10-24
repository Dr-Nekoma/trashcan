{
  lib,
  config,
  hostId,
  profile,
  target,
  specialArgs,
  ...
}:
let
  keys = import ../../keys;
  allKeys = keys.allKeys keys.systems keys.users;
  everyone =
    (
      # Add terraform managed ssh key, if present
      lib.optional (specialArgs ? terraform_ssh_key) specialArgs.terraform_ssh_key
    )
    ++ allKeys;
in
{
  imports = [
    ../../modules
    ../../users
  ];

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  modules.common = {
    enable = true;
  };

  modules.disko = {
    enable = true;
    profile = profile;
    target = target;
  };

  modules.impermanence = {
    enable = true;
  };

  modules.postgresql = {
    enable = true;
  };

  modules.ssh = {
    enable = true;
  };

  modules.secrets = {
    enable = true;
    paths = everyone;
  };

  modules.lyceum = {
    enable = false;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
