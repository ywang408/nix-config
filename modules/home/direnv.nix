{ ... }:
# direnv + nix-direnv: auto-load per-project flake devShells on `cd`.
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
