{ pkgs, lib, modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  # https://github.com/utmapp/UTM/issues/2353
  networking.nameservers = lib.mkIf pkgs.stdenv.isDarwin [ "8.8.8.8" ];

  virtualisation = {
    graphics = false;

    host = {
      inherit pkgs;
    };
  };
}
