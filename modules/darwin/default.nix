{ ... }:
# Aggregates every darwin (system-level) module.
# Add new modules to this list to extend the macOS configuration.
{
  imports = [
    ./nix.nix
    ./system.nix
    ./homebrew.nix
    ./mac-app-store.nix
    ./fonts.nix
  ];
}
