{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        imageSize = "100G";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };
            esp = {
              size = "512M";
              type = "EF00";
              label = "ESP";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            primary = {
              size = "100%";
              label = "nixos";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          home = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          };

          nix = {
            size = "45G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = [
                "defaults"
              ];
            };
          };

          persist = {
            size = "45G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/keep";
              mountOptions = [
                "defaults"
              ];
            };
          };

          swap = {
            size = "4G";
            content = {
              type = "swap";
              resumeDevice = false;
            };
          };
        };
      };
    };
  };
}
