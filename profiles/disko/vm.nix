{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        imageSize = "64G";
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
          root = {
            size = "10%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };

          nix = {
            size = "45%";
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
            size = "35%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/keep";
              mountOptions = [
                "defaults"
              ];
            };
          };

          home = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          };
        };
      };
    };
  };
}
