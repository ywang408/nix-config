{ ... }:
# Declarative Homebrew management via nix-darwin.
#
# nix-darwin does NOT install Homebrew itself — install it once, manually:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# After that, the lists below are the declarative layer on top of your brew.
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # don't `brew update` on every rebuild (faster, predictable)
      upgrade = false;    # let GUI apps self-update; run `brew upgrade` when you want
      # "none"      -> only ADD what's listed below; never remove. SAFE while migrating
      #                (your unlisted brave/helium/mactex/CLI formulae are left alone).
      # "uninstall" -> also remove casks/brews not listed (keeps their app data).
      # "zap"       -> remove anything not listed AND wipe its data (fully declarative).
      # Move to "zap" once this list is complete and you've removed what you don't want:
      #   brew uninstall --cask brave-browser helium-browser mactex
      cleanup = "none";
    };

    # CLI formulae. Keep empty — Nix/Home Manager owns CLI tools now. Your existing
    # brew formulae (mise, starship, sheldon, fzf, zoxide, fd, ripgrep, jq, cmake,
    # yazi, gh, …) are superseded by Nix; uninstall them once Nix is live, then
    # `brew autoremove`.
    brews = [ ];

    # GUI apps + anything needing system permissions live here as casks.
    casks = [
      # --- Browser (you picked Vivaldi) ---
      "vivaldi"

      # --- AI tools ---
      "claude"        # Claude desktop app
      "claude-code"   # Claude Code CLI (provides the `claude` command)
      "codex-app"     # Codex desktop app
      "codex"         # Rust Codex CLI; replaces the old mise npm:@openai/codex

      # --- Editor / terminal ---
      "visual-studio-code"
      "zed"           # used for remote dev over SSH (e.g. into abs)
      "ghostty"

      # --- Productivity ---
      "raycast"       # was not installed — brew installs it on rebuild
      "1password"
      "obsidian"
      "cleanshot"     # needs Screen Recording permission
      "mac-mouse-fix" # needs Accessibility permission

      # --- Communication ---
      "whatsapp"
      "microsoft-teams"
      "zoom"

      # --- Media / reading ---
      "zotero"
      "skim"          # PDF reader

      # --- Input method ---
      "wetype"
      "input-source-pro" # auto-switch + indicator for input sources; needs Accessibility permission

      # Nerd fonts moved to Nix -> modules/darwin/fonts.nix
    ];
  };
}
