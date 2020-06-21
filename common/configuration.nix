{ config, pkgs, ... }:

let
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;

  home-manager =
    fetchTarball
      https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;

  my-python-packages = python-packages: with python-packages; [
    dbus-python
    pygobject3
    gst-python
    # other python packages you want
  ];
  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
in
{
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
      chromium = pkgs.chromium.override { useOzone = true; enableVaapi = true; };
    };
  };

  nixpkgs.overlays = [
    (import (builtins.fetchTarball https://github.com/efouladi/emacs-overlay/archive/master.tar.gz))

    # firefox wayland overlay
    (import (builtins.fetchTarball https://github.com/calbrecht/nixpkgs-overlays/archive/master.tar.gz))
  ];

  imports =
    [
      ./sway.nix
      "${home-manager}/nixos"
    ];

  networking = {
    networkmanager.enable = true;
    useDHCP = false;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Stockholm";

  nix = {
     # this is correct, we're using `nixpkgs-wayland` to cache `nixpkgs-chromium` packages
      binaryCachePublicKeys = [ "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA=" ];
      binaryCaches = [ "https://nixpkgs-wayland.cachix.org" ];
  };

  environment.systemPackages = with pkgs; [
    emacsGccPureGTK
    kitty
    xdg_utils
    desktop-file-utils
    git
    python-with-my-packages
    dropbox
    keepassxc
    pavucontrol
    jq
    networkmanagerapplet
    hicolor-icon-theme
    gnome3.adwaita-icon-theme
    gnome3.dconf
    transmission
    virt-manager
    pinentry-gnome
    firefox-wayland-pipewire-unwrapped
    firefox-wayland-pipewire
    pipewire
    chromium
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  #services.openssh.enable = true;
  #services.openssh.permitRootLogin = "yes";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  nixpkgs.config.pulseaudio = true;
  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  fonts.fonts = with pkgs; [
    font-awesome
  ];

  virtualisation.libvirtd.enable = true;
  programs.gnupg.agent = {
   enable = true;
   pinentryFlavor = "gnome3";
  };
}

