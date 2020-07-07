{ ... }:
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

    };
  };
}
