{ pkgs, ... }:
# tmux — shared across all hosts. Tuned for running long-lived TUI agents
# (codex, claude-code) *inside* tmux, especially over SSH into abs where it
# keeps the agents alive across disconnects.
{
  programs.tmux = {
    enable = true;

    # Leader: C-b -> C-a. (C-Space is already zsh's autosuggest-accept in
    # shell.nix; backtick is painful for code — so C-a.)
    prefix = "C-a";

    mouse = true; # wheel scrolls scrollback; click selects panes / drag resizes
    historyLimit = 100000; # huge scrollback so long agent transcripts stay reachable
    escapeTime = 10; # near-zero ESC delay -> snappy TUIs
    focusEvents = true; # let TUIs react to focus in/out
    keyMode = "vi"; # vi-style copy-mode (v select, y yank)
    baseIndex = 1; # windows/panes count from 1, not 0
    aggressiveResize = true;
    terminal = "tmux-256color";
    # tmux-sensible is included by default (sensibleOnTop) for the usual sane
    # baseline; the settings below intentionally override it where they differ.

    plugins = with pkgs.tmuxPlugins; [
      yank # copy-mode `y` -> system clipboard (works over SSH via OSC52)
      extrakto # prefix+Tab: fzf-grab any path/word/URL off the screen — ideal for agent output
      tmux-fzf # prefix+F: fzf-driven session/window/pane management
      {
        plugin = resurrect; # prefix+C-s save, prefix+C-r restore (layouts survive reboots)
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum; # auto-save every 15 min + auto-restore on tmux start
        extraConfig = ''
          set -g @continuum-save-interval '15'
          set -g @continuum-restore 'on'
        '';
      }
      tokyo-night-tmux # status bar matching the Ghostty TokyoNight theme (needs the Nerd Font, which we have)
    ];

    extraConfig = ''
      # --- Truecolor: declare the outer terminal (Ghostty) as 24-bit RGB so the
      #     agents' diff/syntax colors render correctly inside tmux ---
      set -as terminal-features "xterm-ghostty:RGB"
      set -as terminal-features "xterm-256color:RGB"

      # --- Clipboard / passthrough ---
      # OSC52 set-clipboard: yank inside a tmux on abs lands in the *Mac* clipboard
      # over SSH. allow-passthrough lets apps emit raw escapes (clipboard/images).
      set -g set-clipboard on
      set -g allow-passthrough on

      # Re-assert scrollback last so tmux-sensible can't clamp it back to 50000.
      set -g history-limit 100000

      # --- QoL ---
      setw -g pane-base-index 1
      set -g renumber-windows on # keep window numbers gap-free after closing one
      set -g display-time 2000   # on-screen messages linger 2s

      # Splits inherit the current pane's cwd; | and - are easier to remember
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # prefix + h/j/k/l to move between panes. Deliberately NOT global C-hjkl,
      # so the shell's C-l (clear) and friends stay intact.
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # prefix + r re-reads this config after a rebuild
      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux config reloaded"
    '';
  };
}
