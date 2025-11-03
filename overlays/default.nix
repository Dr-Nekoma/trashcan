{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    # https://github.com/NixOS/nixpkgs/pull/457872
    (self: super: {
      postgresql_18 = super.postgresql_18 // {
        pkgs = super.postgresql_18.pkgs // {
          omnigres = super.postgresql_18.pkgs.omnigres.overrideAttrs (prev: rec {
            cmakeFlags = (prev.cmakeFlags or []) ++ [
              "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
            ];
          });
        };
      };
    })
  ];
}
