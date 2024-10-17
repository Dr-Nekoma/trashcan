{ pkgs, ... }:

{
  services.getty.autologinUser = "root";

  #virtualisation = {
  #  forwardPorts = [
  #    {
  #      from = "host";
  #      guest.port = 80;
  #      host.port = 8080;
  #    }
  #  ];
  #};

  # Networking
  networking.firewall.allowedTCPPorts = [ 80 22 ];
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

  # Users
  users.users = {
    benevides = {
      isNormalUser = true;
      createHome = true;
      description = "Benevides";
      group = "users";
      shell = "/bin/sh";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcb)"
      ];
    };

    kanagawa = {
      isNormalUser = true;
      createHome = true;
      description = "Kanagawa";
      group = "users";
      shell = "/bin/sh";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZudUl8jgFsOYouFL2jXFsADyDSKM0f8k/yCyVwlTMv2O3KTAN58OZcQP0NvaCE1xf0c8Z73sBDQE0LZcCuYvJv3Qfuiur2TOr0YgllnUz9XdkFWBNLykfcuOyo7Lvk0BQxXHJr2ADJVvfLRoaSpubYI40KYe2BJUXtwjUcLEUW8Pd9XknI59hCmgdJpWxotCWimGW5I+r8S5zEdTtMoJWMdDaAgzbw5AL+d227wTL0TKwA1LnCkAISgCCYcUGKG78Q8At1/gN/Q9Vl/v+CR9zYWiPgZihk2aK2LiYPPQbu5hhISyEnnJSIojDhZjCib+4Dt93bfKwMMKJxMF9XFeONINkecCyMOIIcfoGzRPoZNRyjc+TbHc84YuaizmJCHgD17dBnmxwZ75rMZHaKtGq4QJ+phP9bwP9oqAaTdDhFGcr1Ia4ozW2t1T3spDiVC3S5AxiwERLO15IDQwN8plJrIdR2lsQAs4dU3/uA5XEmcnPFVMy32fcKlUwJDMgGmM= mcosta@Marcoss-MacBook-Pro.local"
      ];
    };
  };

  system.stateVersion = "24.05";
}
