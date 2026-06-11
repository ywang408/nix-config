{ pkgs, username, ... }:
# Home Manager entry point, shared by every host (macOS, WSL, server `abs`).
# Each concern is its own module — add to this list to extend.
{
  imports = [
    ./shell.nix
    ./git.nix
    ./cli.nix
    ./dev.nix
    ./yazi.nix
    ./direnv.nix
    ./ssh.nix
  ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
