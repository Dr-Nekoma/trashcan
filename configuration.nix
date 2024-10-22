{ modulesPath, ... }:

{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  zramSwap.enable = true;

  swapDevices = [{
    device = "/swapfile";
    size = 4 * 1024;
  }];
}
