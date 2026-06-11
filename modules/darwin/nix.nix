{ ... }:
# Nix daemon / nixpkgs settings for macOS.
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # IMPORTANT — installer choice:
  # If you installed Nix with the *Determinate Systems* installer, Determinate
  # manages the Nix daemon itself and nix-darwin must NOT also manage it.
  # In that case uncomment the next line, or `darwin-rebuild switch` will abort
  # with: "Determinate detected, aborting activation".
  #
  #   nix.enable = false;
  #
  # If you used the official nix-darwin / upstream Nix installer, leave it as is
  # (nix-darwin manages Nix and the settings above apply).
}
