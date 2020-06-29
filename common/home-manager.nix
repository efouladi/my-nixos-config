{ ... }:
{
  home.file.".config/waybar/config".source = ./dotfiles/waybar.conf;
  programs = {
    git.enable = true;
    ssh.enable = true;
    gpg.enable = true;
    kitty = {
      enable = true;
      settings = {
        enable_audio_bell = false;
      };
    };
  };
}
