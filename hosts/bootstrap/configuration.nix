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
  extraPaths = extraImports."${target}";
in
{
  imports = [
    ../../modules
    ../../users
  ]
  ++ extraPaths;

  modules.disko = {
    enable = true;
    profile = profile;
    target = target;
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  # Nix settings
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    package = pkgs.nixVersions.stable;
    settings.trusted-users = [ "@wheel" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Clean up /nix/store/ after 2 weeks
    gc = {
      automatic = true;
      dates = "weekly UTC";
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  # We don't want the custom ssh module at first, we'll
  # leverage later after everything is setup.
  services.openssh = {
    enable = true;
    settings = {
      # This will be undone after we deployt he real Nekoma VM
      PermitRootLogin = lib.mkForce "yes";
      PasswordAuthentication = false;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "25.11";
}
