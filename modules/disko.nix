{
  lib,
  config,
  modulesPath,
  ...
}:

let
  cfg = config.modules.disko;
  disko_profile_path = ../profiles/disko/. + "/${cfg.profile}.nix";
  disko_profile = import disko_profile_path;
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

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.profile == "aws") {
      disko.devices = disko_profile.disko.devices;

      # Hardware configuration
      hardware.enableRedistributableFirmware = true;
    })

    (mkIf (cfg.profile == "vm") {
      virtualisation.vmVariantWithDisko = {
        disko.devices = disko_profile.disko.devices;

        virtualisation.fileSystems."/".neededForBoot = true;
        # For running VM on macos: https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/
        # virtualisation.host.pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      };
      # This is to make sure we use the same Labels as the
      # qcow2 module from NixOS Generators.
      # https://github.com/nix-community/nixos-generators/blob/master/formats/qcow-efi.nix#L26
      # fileSystems."/" = {
      #   device = mkForce "/dev/disk/by-label/nixos";
      # };
      # fileSystems."/boot" = {
      #   device = mkForce "/dev/disk/by-label/ESP";
      # };
      # swapDevices = mkForce [ ];
    })
  ]);
}
