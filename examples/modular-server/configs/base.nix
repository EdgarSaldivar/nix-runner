# Base system configuration
{ config, lib, pkgs, ... }:

{
  # Boot configuration
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
    hostName = "modular-server";
    useDHCP = lib.mkDefault true;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
  ];

  # Time zone
  time.timeZone = "UTC";
}