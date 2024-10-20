{ pkgs, ... }:

{
  documentation.enable = false;

  # Networking
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      multipliers = "1 2 4 8 16 32 64";
      # Do not ban for more than 1 week
      maxtime = "168h";
      # Calculate the bantime based on all the violations
      overalljails = true;
    };
  };

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

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "deploy" "benevides" "kanagawa" "marinho" ];
      X11Forwarding = false;
      # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
      PermitRootLogin = "prohibit-password";
    };
  };

  # Extra stuff
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # Don't change this!
  system.stateVersion = "24.05";
}
