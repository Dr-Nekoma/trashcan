{ pkgs, ... }:
{
  imports = [ ./bene.nix ./deploy.nix ];

  users = {
    # defaultUserShell = pkgs.zsh;
    mutableUsers = false;
  };
}
