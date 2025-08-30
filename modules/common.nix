{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.common;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
in
{
  options.modules.common = {
    enable = mkEnableOption "Common settings shared by all machines";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      boot = {
        loader = {
          efi.canTouchEfiVariables = true;
        };
        tmp.cleanOnBoot = true;
      };

      documentation.enable = false;

      environment.systemPackages = with pkgs; [
        git
        pciutils
      ];

      networking.networkmanager.enable = true;

      # Nix settings
      nixpkgs = {
        config = {
          allowUnfree = true;
        };
      };

      nix = {
        package = pkgs.nixVersions.stable;
        settings.trusted-users = [ "@wheel" ];
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
        # Clean up /nix/store/ after 2 weeks
        gc = {
          automatic = true;
          dates = "weekly UTC";
          options = "--delete-older-than 14d";
        };
        optimise.automatic = true;
      };

      systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

      # Extra stuff
      # programs.zsh.enable = true;
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
      };

      # Don't change this!
      system.stateVersion = "25.03";
    })
  ];
}
