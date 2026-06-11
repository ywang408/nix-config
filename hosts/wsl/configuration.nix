{ pkgs, username, ... }:
# NixOS-WSL system config (your existing setup, unchanged in spirit).
{
  wsl.enable = true;
  wsl.defaultUser = username;

  # Machine hostname (the prompt's `eric@wsl`, the `hostname` command, and the
  # flake attr `nixosConfigurations.wsl`). Without this, NixOS-WSL defaults it to
  # "nixos". Matches `wslHostname` in flake.nix so `nixos-rebuild switch --flake .`
  # auto-selects this config without an explicit `#name`.
  networking.hostName = "wsl";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.${username} = {
    isNormalUser = true;
    uid = 1001;
    description = username;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide so it's a valid login shell and /etc/zshrc is set up.
  # The user-level zsh config lives in modules/home/shell.nix.
  programs.zsh.enable = true;

  # System-level CLI baseline; most tooling lives in Home Manager (modules/home).
  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
    git
  ];

  nixpkgs.config.allowUnfree = true;

  # Run dynamically-linked (non-Nix) binaries under WSL.
  programs.nix-ld.enable = true;

  system.stateVersion = "25.11";
}
