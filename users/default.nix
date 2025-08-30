{ pkgs, ... }:
{
  imports = [ ./bene.nix ];

  users = {
    # defaultUserShell = pkgs.zsh;
    mutableUsers = false;
  };
}
