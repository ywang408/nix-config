{ pkgs, ... }:
# yazi file manager. `y` wrapper cd's the shell to the last visited dir.
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };

    extraPackages = with pkgs; [
      ffmpeg
      p7zip
      jq
      poppler
      fd
      ripgrep
      fzf
      zoxide
      imagemagick
    ];
  };
}
