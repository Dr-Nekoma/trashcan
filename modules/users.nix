{ pkgs, ... }:

{
  services.getty.autologinUser = "root";

  users.users = {
    benevides = {
      isNormalUser = true;
      createHome = true;
      description = "Benevides";
      group = "users";
      shell = "/bin/sh";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcbZwcStUfn6HFjyWdUb1jZqzQMf3JWeIj3RgP8nKwDatHSVB0GkvSETBiJ+bfbGKK1bacusqfsiN3b2niytDgnWMtKB4tMgvGUn5AEqRBtI5zDrnPU1T7edDCjI32QLBln/HlcfAHz+avN4YsW7iTWu25N/MSOQwBrKHLEQviGq9/j3Wu1pzxV2n2m32uUATFEKLf3sLCdsOWm1r+HlsXOcukUZnRhLc9O2ZVoWtDHo72iOzVY6rlRBoHvoUxw6A8k/jZWb1ospvjOLsjZuAZaDSjcE6iM0nXQSdhgGPSgeCTofOgteYoovA4XlK4aNomuTI3OPLr9P9SLC0qJHidvLIGQYWyMiwdeDJESbY2PFUNCi5VffwEUPYh8sp3E8EwjGDvSCygu4fU7vqaOi3OEziwg2ff89CdVr7k606LYmRF3dR+12Cp6XBOgUoaz+OzGn0Sr9HXw3GiF9xH/e1PL6mHwUT2NARB/mI64uY9JAi0/hrwkQsiIx1tf63qUDz/je9gk53wP7/GfWNoIeEkRzCz0QkEnxcMEoLjbTk56JFkmP0fpHDQ== (none)"
      ];
    };

    kanagawa = {
      isNormalUser = true;
      createHome = true;
      description = "Kanagawa";
      group = "users";
      shell = "/bin/sh";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZudUl8jgFsOYouFL2jXFsADyDSKM0f8k/yCyVwlTMv2O3KTAN58OZcQP0NvaCE1xf0c8Z73sBDQE0LZcCuYvJv3Qfuiur2TOr0YgllnUz9XdkFWBNLykfcuOyo7Lvk0BQxXHJr2ADJVvfLRoaSpubYI40KYe2BJUXtwjUcLEUW8Pd9XknI59hCmgdJpWxotCWimGW5I+r8S5zEdTtMoJWMdDaAgzbw5AL+d227wTL0TKwA1LnCkAISgCCYcUGKG78Q8At1/gN/Q9Vl/v+CR9zYWiPgZihk2aK2LiYPPQbu5hhISyEnnJSIojDhZjCib+4Dt93bfKwMMKJxMF9XFeONINkecCyMOIIcfoGzRPoZNRyjc+TbHc84YuaizmJCHgD17dBnmxwZ75rMZHaKtGq4QJ+phP9bwP9oqAaTdDhFGcr1Ia4ozW2t1T3spDiVC3S5AxiwERLO15IDQwN8plJrIdR2lsQAs4dU3/uA5XEmcnPFVMy32fcKlUwJDMgGmM= mcosta@Marcoss-MacBook-Pro.local"
      ];
    };
  };
}
