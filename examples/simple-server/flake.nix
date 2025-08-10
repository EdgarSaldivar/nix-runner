{
  description = "Simple NixOS server with SSH and nginx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          # Basic system configuration
          boot.loader.grub.device = "/dev/sda";
          
          # Filesystem configuration
          fileSystems."/" = {
            device = "/dev/sda1";
            fsType = "ext4";
          };
          
          # System version
          system.stateVersion = "24.05";
          
          # Network configuration
          networking = {
            hostName = "simple-server";
            firewall.allowedTCPPorts = [ 22 80 443 ];
          };

          # Enable SSH service
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };

          # Enable nginx web server
          services.nginx = {
            enable = true;
            virtualHosts."example.com" = {
              root = "/var/www/html";
              locations."/" = {
                index = "index.html";
              };
            };
          };

          # Users configuration
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9q7YZ8vK0Z1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y1Y user@example.com"
            ];
          };

          # Enable sudo for wheel group
          security.sudo.wheelNeedsPassword = false;

          # System packages
          environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
            vim
            curl
            htop
          ];
        }
      ];
    };
  };
}