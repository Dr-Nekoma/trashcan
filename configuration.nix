{
  lib,
  isImageTarget,
  extraModules,
  ...
}:
{
  imports =
    lib.optionals (!isImageTarget) [
      ./hardware-configuration.nix
      ./disko-config.nix
    ]
    ++ extraModules;
}
