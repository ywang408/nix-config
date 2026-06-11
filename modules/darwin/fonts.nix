{ pkgs, ... }:
# Fonts installed system-wide via nix-darwin (lands in /Library/Fonts).
# Moved here from Homebrew casks. After switching, remove the brew ones:
#   brew uninstall --cask font-jetbrains-mono-nerd-font font-symbols-only-nerd-font
{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
}
