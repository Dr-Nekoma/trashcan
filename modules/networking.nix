{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lsof
  ];

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.hostName = "trashcan";

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

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "deploy" "benevides" "kanagawa" "lemos" "magueta" "marinho" ];
      X11Forwarding = false;
      # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
      PermitRootLogin = "prohibit-password";
    };
  };
}
