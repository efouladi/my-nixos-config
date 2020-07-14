{ pkgs, ... }:
let
  waybar-config = {
    layer = "top";
    position = "bottom";
    height = 30;
    modules-left = ["sway/workspaces" "sway/mode"];
    modules-center = ["sway/window"];
    modules-right = ["idle_inhibitor" "pulseaudio" "cpu" "memory" "temperature" "backlight" "battery" "clock" "custom/layout" "custom/caps" "tray"];

    "sway/mode" = {
      format = "<span style=\"italic\">{}</span>";
    };

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "";
        deactivated = "";
      };
    };

    pulseaudio = {
      # scroll-step = 1, // %, can be a float
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = " {icon} {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphones = "";
        handsfree = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = ["" "" ""];
      };
      on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
    };

    cpu = {
      format = "{usage}% ";
      tooltip = false;
    };

    memory = {
      format = "{}% ";
    };

    temperature = {
      # thermal-zone = 2;
      # hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
      critical-threshold = 80;
      # format-critical = "{temperatureC}°C {icon}";
      format = "{temperatureC}°C {icon}";
      format-icons = ["" "" ""];
    };

    backlight = {
      # device = "acpi_video1";
      format = "{percent}% {icon}";
      format-icons = ["" ""];
    };

    battery = {
      states = {
        # good = 95;
        warning = 30;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      # format-good = "", # An empty format will hide the module
      # format-full = "";
      format-icons = ["" "" "" "" ""];
    };

    clock = {
      tooltip-format = "{:%Y-%m-%d | %H:%M}";
      format-alt = "{:%Y-%m-%d}";
    };

    "custom/layout" = {
      tooltip = false;
      exec = "${pkgs.sway}/bin/swaymsg -mrt subscribe '[\"input\"]' | ${pkgs.jq}/bin/jq -r --unbuffered \"select(.change == \\\"xkb_layout\\\") | .input | select(.type == \\\"keyboard\\\") | .xkb_active_layout_name | .[0:2] | ascii_upcase\"";
    };

    "custom/caps" = {
      tooltip = false;
      exec = "while sleep 1; do if [ $(cat /sys/class/leds/*::capslock/brightness) -gt 0 ] ; then echo \" CAPS\"; else echo \"\"; fi done";
    };

    tray = {
      # icon-size = 21;
      spacing = 10;
    };

  };
in
{
  home.file.".config/waybar/config".text = (builtins.toJSON waybar-config);
  programs = {
    git.enable = true;
    ssh.enable = true;
    gpg.enable = true;
    alacritty.enable = true;
    mako = {
      enable = true;
      defaultTimeout = 5000;
    };
  };

  services.network-manager-applet.enable = true;
  xsession.preferStatusNotifierItems = true;
  gtk = {
    enable = true;
    font = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans 10";
    };
    gnome-keyring.enable = true;
  };
}
