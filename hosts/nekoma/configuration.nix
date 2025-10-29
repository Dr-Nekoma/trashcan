{
  lib,
  config,
  hostId,
  modulesPath,
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
  extraPaths = extraImports."${target}";
in
{
  imports = [
    ../../modules
    ../../users
  ]
  ++ extraPaths;

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

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
