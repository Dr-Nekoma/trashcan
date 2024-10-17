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
    deploy = {
      isNormalUser = true;
      createHome = true;
      description = "Deploy User";
      group = "users";
      shell = "/bin/sh";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcb)"
      ];
    };
  };

  system.stateVersion = "24.05";
}
