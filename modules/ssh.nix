{ lib, config, ... }:

let
  cfg = config.modules.ssh;
  disko_module = config.modules.disko;
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

    # Impermance-based configs
    # https://discourse.nixos.org/t/how-to-define-actual-ssh-host-keys-not-generate-new/31775/8
    ## If enabled
    (mkIf (impermanence_module.enable) {
      services.openssh.extraConfig = "HostKey /run/secrets/server_ssh";
    })

    ## Otherwise
    (mkIf (!impermanence_module.enable) {
      services.openssh.extraConfig = "HostKey /etc/agenix/server_key";
    })
  ];
}
