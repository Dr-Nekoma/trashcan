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
    disk.main = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          nix = {
            size = "10G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
            };
          };
          persist = {
            size = "5G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
            };
          };
        };
      };
    };
    
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "size=2G" "mode=755" ];
    };
  };
}
