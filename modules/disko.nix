{
  lib,
  config,
  modulesPath,
  ...
}:

let
  cfg = config.modules.disko;
  profile_path = ../profiles/. + "/${cfg.profile}.nix";
  profile = import profile_path;
  inherit (lib)
    mkEnableOption
    mkIf
    mkForce
    mkMerge
    mkOption
    ;
in
{
  options.modules.disko = {
    enable = mkEnableOption "Disko module";
    profile = mkOption {
      type = lib.types.str;
      default = null;
      description = "The profile to use for the disko module.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Disk Setup
      disko.devices = profile.disko.devices;
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

      # This is to make sure we use the same Labels as the
      # qcow2 module from NixOS Generators.
      # https://github.com/nix-community/nixos-generators/blob/master/formats/qcow-efi.nix#L26
      fileSystems."/" = {
        device = mkForce "/dev/disk/by-label/nixos";
      };
      fileSystems."/boot" = {
        device = mkForce "/dev/disk/by-label/ESP";
      };
      swapDevices = mkForce [ ];

      # Disable automatic filesystem creation from nixos-generators
      system.build.qemuFormatOverride = true;

      # Hardware configuration
      hardware.enableRedistributableFirmware = true;

      # Autologin to root
      services.getty.autologinUser = "root";
      security.sudo.wheelNeedsPassword = false;
    })
  ];

}
