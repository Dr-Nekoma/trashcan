{ target }:
let
  deviceOptions = {
    "aws" = "nvme0n1";
    "mgc" = "vda";
    "vm" = "vda";
  };
  device = deviceOptions."${target}";
in
{
  devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/${device}";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            nix = {
              size = "50%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
              };
            };
            persist = {
              size = "50%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persist";
              };
            };
          };
        };
      };
    };

    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=50%"
          "mode=755"
        ];
      };
    };
  };
}
