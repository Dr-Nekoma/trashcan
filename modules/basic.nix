{ pkgs, ... }:

{
  documentation.enable = false;

  environment.systemPackages = with pkgs; [
    lsof
  ];

  networking.networkmanager.enable = true;

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

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [
        "nixos"
        "bene"
      ];
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
  system.stateVersion = "25.03";
}
