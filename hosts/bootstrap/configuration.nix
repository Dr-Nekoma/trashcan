{
  lib,
  config,
  diskoProfile,
  hostId,
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
  };

  modules.disko = {
    enable = true;
    profile = diskoProfile;
  };

  modules.ssh = {
    enable = true;
  };

  modules.secrets = {
    enable = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
