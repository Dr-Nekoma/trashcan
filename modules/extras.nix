{ pkgs, ... }:

{
  documentation.enable = false;

  # Networking
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  services.openssh.enable = true;

  # Nix configuration
  nix.settings.trusted-users = ["@wheel"];
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

  # Don't change this!
  system.stateVersion = "24.05";
}
