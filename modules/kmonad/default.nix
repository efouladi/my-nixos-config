{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.kmonad;
  kmonad = import ../../pkgs/kmonad;
in
{

  ###### interface
  options = {
    hardware.kmonad = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to configure system to use kmonad keyboard mapping.
          To grant access to a user, it must be part of input and uinput groups:
          <code>users.users.alice.extraGroups = ["input" "uinput"];</code>
        '';
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.udev.extraRules =
    ''
      # KMonad user access to /dev/uinput
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    boot.kernelModules = [ "uinput" ];
    environment.systemPackages = [ kmonad ];

    systemd.user.services.kmonad = {
      preStart = "sleep 1";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${kmonad}/bin/kmonad .config/kmonad/config";
    };
    users.groups.uinput = {};
  };
}
