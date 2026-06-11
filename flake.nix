{
  description = "Eric's NixOS (WSL) and macOS (nix-darwin) configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # macOS system management
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # User-level config shared across hosts
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS-WSL
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nixos-wsl, ... }:
    let
      username = "eric"; # same account name on every host

      # macHostname matches `scutil --get LocalHostName` so `darwin-rebuild switch`
      # auto-selects this config (else pass `--flake .#<name>` explicitly).
      macHostname = "Erics-MacBook-Pro";
      # wslHostname matches `networking.hostName` (set in hosts/wsl/configuration.nix)
      # so `nixos-rebuild switch --flake .` auto-selects this config too.
      wslHostname = "wsl";
      # abs = bare-metal NixOS server (i7-14700 + RTX 5060). Matches
      # networking.hostName in hosts/server/configuration.nix.
      serverHostname = "abs";

      # Shared Home Manager wiring, reused by every host.
      homeManagerModule = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # On the first switch, rename pre-existing dotfiles (e.g. ~/.zshrc,
        # ~/.gitconfig, ~/.config/sheldon/plugins.toml) to *.backup instead of
        # aborting. Remove the .backup files once you've confirmed the switch.
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs username; };
        home-manager.users.${username} = import ./modules/home;
      };
    in
    {
      # ---------- macOS (Apple Silicon) ----------
      darwinConfigurations.${macHostname} = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/macbook/darwin.nix
          home-manager.darwinModules.home-manager
          homeManagerModule
        ];
      };

      # ---------- NixOS-WSL ----------
      nixosConfigurations.${wslHostname} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs username; };
        modules = [
          nixos-wsl.nixosModules.default
          ./hosts/wsl/configuration.nix
          home-manager.nixosModules.home-manager
          homeManagerModule
        ];
      };

      # ---------- NixOS server (abs) ----------
      nixosConfigurations.${serverHostname} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/server/configuration.nix
          home-manager.nixosModules.home-manager
          homeManagerModule
        ];
      };
    };
}
