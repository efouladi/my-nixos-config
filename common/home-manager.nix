{ pkgs, ... }:
{
  home.file.".config/waybar/config".source = ./dotfiles/waybar.conf;
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
  };
}
