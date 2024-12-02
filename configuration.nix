{ modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Nix configuration
  nix.settings.trusted-users = [ "@wheel" ];
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Clean up /nix/store/ after a week
    gc = {
      automatic = true;
      dates = "weekly UTC";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  # Don't change this!
  system.stateVersion = "24.11";
}
