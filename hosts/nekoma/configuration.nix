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

  # ZFS support
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.supportedFilesystems = [ "zfs" ];
  # boot.zfs.forceImportRoot = false;
  #
  # fileSystems."/" = lib.mkForce {
  #   device = "tank/root";
  #   fsType = "zfs";
  #   options = [ "zfsutil" ];
  # };

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
