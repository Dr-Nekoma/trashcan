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
            boot = {
              size = "1M";
              type = "EF02";
            };
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
