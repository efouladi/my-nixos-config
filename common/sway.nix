{ config, pkgs, lib, ... }:

let
   waylandOverlay = (import (builtins.fetchTarball https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz));
in
{
  nixpkgs.overlays = [ waylandOverlay ];
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swaylock # lockscreen
      swayidle
      xwayland # for legacy apps
      waybar # status bar
      mako # notification daemon
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
    (
      pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.bash}/bin/bash

          # first import environment variables from the login manager
          systemctl --user import-environment
          # then start the service
          exec systemctl --user start sway.service
        '';
      }
    )
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
      sway = {
        description = "Sway - Wayland window manager";
        documentation = [ "man:sway(5)" ];
        bindsTo = [ "graphical-session.target" ];
        wants = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
        # We explicitly unset PATH here, as we want it to be set by
        # systemctl --user import-environment in startsway
        environment = {
          PATH = lib.mkForce null;
          MOZ_ENABLE_WAYLAND = "1";
          WLR_DRM_NO_MODIFIERS = "1";
          XDG_CURRENT_DESKTOP = "sway";# https://github.com/emersion/xdg-desktop-portal-wlr/issues/20
          XDG_SESSION_TYPE = "wayland";# https://github.com/emersion/xdg-desktop-portal-wlr/pull/11
        };
        serviceConfig = {
          Type = "simple";
          ExecStart = ''
            ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug
          '';
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

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
