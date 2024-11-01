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

    virtualHosts.localhost = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };

      locations."/robots.txt" = {
        extraConfig = ''
          rewrite ^/(.*)  $1;
          return 200 "User-agent: *\nDisallow: /";
        '';
      };
    };
  };
}
