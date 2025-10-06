{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.common;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
in
{
  options.modules.lyceum = {
    enable = mkEnableOption "Enable Lyceum's backend";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      networking = {
        # I don't like it, but we need to fix the game
        # before disabling this.
        # https://github.com/Dr-Nekoma/lyceum/issues/66
        firewall = {
          allowedTCPPorts = [ 4369 ];
          allowedUDPPorts = [ 4369 ];
        };
      };
    })
  ]);
}
