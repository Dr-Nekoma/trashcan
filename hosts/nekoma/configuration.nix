{
  lib,
  config,
  hostId,
  profile,
  ...
}:
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
    profile = profile;
  };

  modules.disko = {
    enable = false;
    profile = profile;
  };

  modules.ssh = {
    enable = true;
  };

  modules.secrets = {
    enable = true;
  };

  modules.postgresql = {
    enable = true;
  };

  # modules.impermanence = {
  #   enable = true;
  # };

  # modules.lyceum = {
  #   enable = true;
  # };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
