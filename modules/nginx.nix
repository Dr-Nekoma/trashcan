{ pkgs, config, modulesPath, ... }:

{
  #security.acme.defaults.email = "<todo>";
  #security.acme.acceptTerms = true;
  services.nginx = {
    enable = true;
    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    #recommendedTlsSettings = true;

    streamConfig = ''
      server {
          listen 8080;
          proxy_pass localhost:8080;
      }
    '';

    virtualHosts.localhost = {
      locations."/robots.txt" = {
        extraConfig = ''
          rewrite ^/(.*)  $1;
          return 200 "User-agent: *\nDisallow: /";
        '';
      };
    };
  };
}
