{ ... }:
{
  home.file.".config/waybar/config".source = ./waybar.conf;
  programs = {
    git.enable = true;
    ssh.enable = true;
    gpg.enable = true;
  };
}
