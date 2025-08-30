{ lib, config, ... }:

let
  cfg = config.modules.ssh;
  impermanence_module = config.modules.impermanence;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
in
{
  options.modules.ssh = {
    enable = mkEnableOption "Enable/Disable custom SSH options";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
          AllowUsers = [
            "bene"
          ];
          X11Forwarding = false;
          # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
          PermitRootLogin = "prohibit-password";
        };
      };
    })

    (mkIf impermanence_module.enable {
      services.openssh = {
        hostKeys = [
          {
            type = "ed25519";
            path = "${impermanence_module.directory}/etc/ssh/ssh_host_ed25519_key";
          }
          {
            type = "rsa";
            bits = 4096;
            path = "${impermanence_module.directory}/etc/ssh/ssh_host_rsa_key";
          }
        ];
      };
    })
  ];
}
