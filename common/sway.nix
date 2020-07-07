{ config, pkgs, lib, ... }:

let
   waylandOverlay = (import (builtins.fetchTarball https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz));
in
{
  nixpkgs.overlays = [ waylandOverlay ];
  programs.sway = {
    enable = true;
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # Fix for some Java AWT applications (e.g. Android Studio),
      # use this if they aren't displayed properly:
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export WLR_DRM_NO_MODIFIERS=1
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
    '';
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock # lockscreen
      swayidle
      xwayland # for legacy apps
      waybar # status bar
      kanshi # autorandr
      wofi
      wdisplays
      wl-clipboard
      xdg-desktop-portal-wlr
      xdg-desktop-portal
    ];
  };

  # environment = {
  #   etc = {
  #     # Put config files in /etc. Note that you also can put these in ~/.config, but then you can't manage them with NixOS anymore!
  #     "sway/config".source = ./dotfiles/sway/config;
  #     "xdg/waybar/config".source = ./dotfiles/waybar/config;
  #     "xdg/waybar/style.css".source = ./dotfiles/waybar/style.css;
  #   };
  # };

  # Here we but a shell script into path, which lets us start sway.service (after importing the environment of the login shell).
  environment.systemPackages = with pkgs; [
    (pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.bash}/bin/bash

          # Environment
          while read -r l; do
              eval export $l
          done < <(/run/current-system/sw/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)

          exec systemd-cat --identifier=sway sway
        '';
    })
  ];

  # services.redshift = {
  #   enable = true;
  #   # Redshift with wayland support isn't present in nixos-19.09 atm. You have to cherry-pick the commit from https://github.com/NixOS/nixpkgs/pull/68285 to do that.
  #   package = pkgs.redshift-wlr;
  # };

  programs.waybar.enable = true;
  services.pipewire.enable = false;

  services.fcron = {
    enable = true;
    systab = ''
      &mail(false),bootrun(true) 1 7 * * * /bin/sh -c "curl 'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1' | jq -r .images[0].url | awk '{print \"https://www.bing.com\"\$1}' | xargs curl -o '/tmp/wallpaper.jpg' && swaymsg -s /run/user/1000/sway-ipc.1000.\$(pidof sway).sock output \"*\" background /tmp/wallpaper.jpg fill";
    '';
  };


  xdg = {
    icons.enable = true;
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-wlr
      ];
      gtkUsePortal = true;
    };
  };

  systemd.user = {
    targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    services = {

      kanshi = {
        description = "Kanshi output autoconfig ";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          # kanshi doesn't have an option to specifiy config file yet, so it looks
          # at .config/kanshi/config
          ExecStart = ''
            ${pkgs.kanshi}/bin/kanshi
          '';
          RestartSec = 5;
          Restart = "always";
        };
      };

      pipewire = {
        enable = true;
        description = "Multimedia Service";

        environment = {
          PIPEWIRE_DEBUG = "4";
        };
        path = [ pkgs.pipewire ];
        requires= [ "pipewire.socket" "xdg-desktop-portal.service" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.pipewire}/bin/pipewire";
          Restart = "on-failure";
        };

        wantedBy = [ "default.target" ];
      };

      xdg-desktop-portal-wlr = {
        enable = true;
        description = "Portal service (wlroots implementation)";

        requires= [ "pipewire.service" ];

        serviceConfig = {
          Type = "dbus";
          BusName = "org.freedesktop.impl.portal.desktop.wlr";
          ExecStart = [
            "" # Override for trace
            "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr -l TRACE"
          ];
          Restart = "on-failure";
        };
      };

      swayidle = {
        description = "Idle manager for Wayland";
        documentation = [ "man:swayidle(1)" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = ''
                    ${pkgs.swayidle}/bin/swayidle -w \
                      timeout 300 '${pkgs.swaylock}/bin/swaylock -f -c 000000' \
                      timeout 600 '${pkgs.sway}/bin/swaymsg output * dpms off' \
                      resume '${pkgs.sway}/bin/swaymsg output * dpms on' \
                      before-sleep '${pkgs.swaylock}/bin/swaylock -f -c 000000'
                    '';
          Restart = "on-failure";
        };
      };

      polkit-gnome = {
        description = "Legacy polkit authentication agent for GNOME";
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
      };

    };

    sockets.pipewire = {
      enable = true;

      socketConfig = {
        Priority = 6;
        Backlog = 5;
        ListenStream= "%t/pipewire-0";
      };
    };
  };
}
