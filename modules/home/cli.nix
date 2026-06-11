{ pkgs, ... }:
# General-purpose CLI utilities (cross-platform).
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    fzf
    zoxide
    bat
    eza
    gh
  ];
}
