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
    mkOption
    ;
in
{
  options.modules.common = {
    enable = mkEnableOption "Common settings shared by all machines";
    profile = mkOption {
      type = lib.types.str;
      default = null;
      description = "The profile to use for the common module.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      boot = {
        loader = {
          efi.canTouchEfiVariables = true;
        };
        tmp.cleanOnBoot = true;
      };

      documentation.enable = false;

      environment.systemPackages = with pkgs; [
        bash
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

      # Extra stuff
      # programs.zsh.enable = true;
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
      };

      # Don't change this!
      system.stateVersion = "25.05";
    })

    (mkIf (cfg.profile == "aws") {
      # Hardware configuration
      hardware.enableRedistributableFirmware = true;
    })

    (mkIf (cfg.profile == "vm") {
      # Enable QEMU guest agent
      services.qemuGuest.enable = true;

      # Boot configuration
      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];
      boot.kernelModules = [ ];

      # Disable automatic filesystem creation from nixos-generators
      system.build.qemuFormatOverride = true;

      # Hardware configuration
      hardware.enableRedistributableFirmware = true;

      # Autologin to root
      services.getty.autologinUser = "root";
      security.sudo.wheelNeedsPassword = false;
    })
  ]);
}
