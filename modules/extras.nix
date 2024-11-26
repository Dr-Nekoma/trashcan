{ pkgs, ... }:

{
  documentation.enable = false;

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      dates = "weekly";
      enable = true;
      flags = [ "--all" ];
    };
  };

  # Extra stuff
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
}
