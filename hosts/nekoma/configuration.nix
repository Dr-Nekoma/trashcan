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
  boot.loader.systemd-boot.enable = true;

  modules.common = {
    enable = true;
    profile = profile;
  };

  modules.disko = {
    enable = true;
    profile = profile;
  };

  modules.impermanence = {
    enable = false;
  };

  modules.postgresql = {
    enable = true;
  };

  modules.ssh = {
    enable = true;
  };

  modules.secrets = {
    enable = true;
  };

  modules.lyceum = {
    enable = false;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
