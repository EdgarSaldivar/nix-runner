# Web services module
{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts."example.local" = {
      root = "/var/www/html";
      locations."/" = {
        index = "index.html";
      };
      locations."/api" = {
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  environment.systemPackages = with pkgs; [
    curl
    htop
  ];
}