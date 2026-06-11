{ pkgs, lib, ... }:
# Shells — zsh on every host (macOS + WSL). bash is kept only on Linux as a
# fallback; macOS uses the built-in zsh, so we don't manage bash there.
{
  programs.bash = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    shellAliases = {
      ll = "ls -lah";
    };
  };

  programs.zsh = {
    enable = true;

    # We run compinit ourselves (below) rather than letting HM run it, so it lands
    # before sheldon sources fzf-tab. nix-darwin's /etc/zshrc already adds the
    # profile completion dirs to fpath before this runs, so no manual fpath needed.
    enableCompletion = false;

    shellAliases = {
      ll = "ls -lah";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      tailscale = "TAILSCALE_BE_CLI=1 /Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };

    # Ported from ~/.zshrc. Order is load-bearing for fzf-tab.
    # (mise activation removed — uv/ruff/node now come from Nix, codex from brew.)
    # Note: `${(s.:.)LS_COLORS}` is escaped as ''${...} for the Nix parser.
    initContent = ''
      # --- Completion (BEFORE sheldon so fzf-tab can hook in) ---
      autoload -Uz compinit
      compinit

      # --- fzf shell integration (keybindings + completion) ---
      source <(fzf --zsh)

      # --- Sheldon plugin manager ---
      eval "$(sheldon source)"

      # fzf-tab config
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      # --- Keybindings ---
      bindkey '^ ' autosuggest-accept

      # --- Tools ---
      eval "$(zoxide init zsh)"
      eval "$(starship init zsh)"
    '';
  };

  # Prompt + plugin manager (fzf and zoxide come from modules/home/cli.nix).
  # zsh-completions provides the completion collection; it's in the profile, so
  # nix-darwin's /etc/zshrc puts it on fpath automatically.
  home.packages = with pkgs; [
    starship
    sheldon
    zsh-completions
  ];

  # sheldon plugin list, pulled verbatim from ~/.config/sheldon/plugins.toml.
  # sheldon clones/caches the listed plugins itself on first shell start.
  xdg.configFile."sheldon/plugins.toml".source = ./files/sheldon/plugins.toml;
}
