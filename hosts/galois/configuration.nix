{ config, pkgs, ... }:
let
  nixos-hardware =
    fetchTarball
      https://github.com/NixOS/nixos-hardware/archive/master.tar.gz;
in
{
  imports =
    [
      ../../common/configuration.nix
      "${nixos-hardware}/lenovo/thinkpad/x230"
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "galois";
  networking.interfaces = {
    eno0.useDHCP = true;
    wlp2s0.useDHCP = true;
  };

  programs.adb.enable = true;

  users.users.shafo = {
    home = "/home/shafo";
    isNormalUser = true;
    extraGroups = [ "wheel"
                    "networkmanager"
                    "audio"
                    "libvirtd"
                    "adbusers"
                    "video"
                  ];
  };

  swapDevices = [ { device = "/swapfile"; size = 4096; } ];

  home-manager.users.shafo = { ... }: {
    imports = [ ../../common/home-manager.nix ];
    home.file = {
      ".config/sway/config".source = ./dotfiles/sway.conf;
      ".config/kanshi/config".source = ./dotfiles/kanshi.conf;
    };
    programs.git = {
      userEmail = "efouladi@gmx.com";
      userName = "Shayan Fouladi";
      signing.key = "EEB41F44";
      signing.signByDefault = true;
    };
  };

  services.syncthing = {
    enable = true;
    user = "shafo";
    dataDir = "/home/shafo/.syncthing";
    configDir = "/home/shafo/.syncthing";
    openDefaultPorts = true;
  };
}
