{ pkgs, ... }:

{
  services.getty.autologinUser = "root";

  environment.systemPackages = with pkgs; [
    barman
    pgbouncer
  ];

  #virtualisation = {
  #  forwardPorts = [
  #    {
  #      from = "host";
  #      guest.port = 80;
  #      host.port = 8080;
  #    }
  #  ];
  #};

  # Postgres
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      shared_preload_libraries = "pg_stat_statements";
      # pg_stat_statements config, nested attr sets need to be
      # converted to strings, otherwise postgresql.conf fails
      # to be generated.
      compute_query_id = "on";
      "pg_stat_statements.max" = 10000;
      "pg_stat_statements.track" = "all";
    };
    extraPlugins = with pkgs.postgresql_16.pkgs; [
      periods
      repmgr
    ];
    initialScript = pkgs.writeText "init-sql-script" ''
      CREATE EXTENSION pg_stat_statements;
    '';
  };

  # haproxy
  #services.haproxy = {
  #  enable = true;
  #};

  # keepalived
  services.keepalived = {
    enable = true;
  };

  # Networking
  networking.firewall.allowedTCPPorts = [ 80 22 ];
  services.openssh.enable = true;

  # Nix configuration
  nix.settings.trusted-users = ["@wheel"];
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Clean up /nix/store/ after a week
    gc = {
      automatic = true;
      dates = "weekly UTC";
      options = "--delete-older-than 7d";
    };
  };

  # Users
  users.users = {
    deploy = {
      isNormalUser = true;
      createHome = true;
      description = "Deploy User";
      group = "users";
      shell = "/bin/sh";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcb)"
      ];
    };
  };

  system.stateVersion = "24.05";
}
