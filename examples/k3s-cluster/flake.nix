{
  description = "NixOS k3s cluster with SSH";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.k3s-node = nixpkgs.lib.nixosSystem {
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
            hostName = "k3s-node";
            firewall = {
              allowedTCPPorts = [ 22 6443 ];
              allowedUDPPorts = [ 8472 ];
            };
          };

          # Enable SSH service
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };

          # Enable k3s service
          services.k3s = {
            enable = true;
            role = "server";
            extraFlags = toString [
              "--cluster-cidr=10.42.0.0/16"
              "--service-cidr=10.43.0.0/16"
              "--write-kubeconfig-mode=644"
            ];
          };

          # Enable Docker for k3s
          virtualisation.docker = {
            enable = true;
            enableOnBoot = true;
          };

          # Users configuration
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" "docker" ];
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
            kubectl
            kubernetes-helm
          ];
        }
      ];
    };
  };
}