# SSH service module
{ config, lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9q7YZ8vK0Z1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y user@example.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}