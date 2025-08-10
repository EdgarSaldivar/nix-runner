{
  description = "Modularized NixOS server with SSH and web services";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.web-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Base system configuration
        ./configs/base.nix
        
        # Service modules
        ./modules/ssh.nix
        ./modules/web.nix
      ];
    };
    
    nixosConfigurations.ssh-only = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Base system configuration
        ./configs/base.nix
        
        # Only SSH service
        ./modules/ssh.nix
      ];
    };
  };
}