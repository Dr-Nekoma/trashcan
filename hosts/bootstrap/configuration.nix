{
  lib,
  config,
  modulesPath,
  hostId,
  pkgs,
  profile,
  target,
  specialArgs,
  ...
}:
let
  extraImports = {
    "aws" = [
      "${modulesPath}/virtualisation/amazon-image.nix"
    ];
    "mgc" = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];
    "vm" = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];
  };
  swapOptions = {
    "aws" = 16;
    "mgc" = 16;
    "vm" = 4;
  };
  extraPaths = extraImports."${target}";
  swapSize = swapOptions."${target}";
in
{
  imports = [
    ../../modules
    ../../users
  ]
  ++ extraPaths;

  modules.common = {
    enable = true;
    swap = {
      enable = true;
      size = swapSize;
    };
  };

  modules.disko = {
    enable = true;
    profile = profile;
    target = target;
  };

  modules.ssh = {
    enable = true;
  };

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  # We don't want the custom ssh module at first, we'll
  # leverage later after everything is setup.
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     # This will be undone after we deployt he real Nekoma VM
  #     PermitRootLogin = lib.mkForce "yes";
  #     PasswordAuthentication = false;
  #   };
  # };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
