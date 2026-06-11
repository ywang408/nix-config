{ pkgs, username, ... }:
# Core macOS system settings and sane defaults.
{
  # Apple Silicon. Intel Macs: change to "x86_64-darwin".
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required by recent nix-darwin: the user that owns user-level state and
  # the one you run `darwin-rebuild` as.
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # nix-darwin sets up shell integration (PATH to /run/current-system/sw/bin)
  # in /etc/zshrc when zsh is enabled here.
  programs.zsh.enable = true;

  # A tiny system-level baseline; prefer Home Manager (modules/home) for tools.
  environment.systemPackages = with pkgs; [
    # neovim
    # git
  ];

  # macOS UI/UX defaults — extend freely.
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
    };
  };

  # Compatibility marker. Set once on first install and leave it.
  # Latest as of 2026-05 is 7; 6 is widely used and safe. Do not bump casually.
  system.stateVersion = 6;
}
