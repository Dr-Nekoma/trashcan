{ modulesPath, ... }:

{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  zramSwap.enable = true;

  swapDevices = [{
    device = "/swapfile";
    size = 8 * 1024;
  }];
}
