{
  lib,
  config,
  modulesPath,
  ...
}:

let
  cfg = config.modules.disko;
  disko_profile_path = ../profiles/disko/. + "/${cfg.profile}.nix";
  disko_settings = import disko_profile_path { target = cfg.target; };
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
      description = "The target to use for the disko module. Can be either 'bootstrap' or 'persistence'.";
    };

    target = mkOption {
      type = lib.types.str;
      description = "The profile to use for the disko module. Can be either 'aws', 'mgc' or 'vm'.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.target == "aws") {
      disko.devices = disko_settings.devices;
    })

    (mkIf (cfg.target == "mgc") {
      boot = {
        initrd.availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
        ];
        kernelModules = [ "kvm-intel" ];
      };

      boot.loader.grub.devices = lib.mkForce [ "/dev/vda" ];

      disko.devices = disko_settings.devices;
    })

    (mkIf (cfg.target == "vm") {
      boot.loader.grub.devices = lib.mkForce [ "/dev/vda" ];

      disko.devices = disko_settings.devices;

      virtualisation.vmVariantWithDisko = {
        # 40GB in MB
        virtualisation.diskSize = 40960;
        # 4GB RAM
        virtualisation.memorySize = 4096; 
        virtualisation.fileSystems."/".neededForBoot = true;
        virtualisation.fileSystems."/nix".neededForBoot = true;
        virtualisation.fileSystems."/persist".neededForBoot = true;
        # For running VM on macos: https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/
        # virtualisation.host.pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      };
    })
  ]);
}
