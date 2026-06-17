{ pkgs, lib, ... }:
# Development toolchains. Per-project versions belong in flake devShells;
# these are the global baselines.
{
  home.packages = with pkgs; [
    # Python — uv manages the interpreters + venvs; these are just editor tooling.
    uv
    ruff
    pyright

    # Node / JS
    nodejs_22
    bun

    # C / C++ build tools. The compiler itself is the system clang on macOS
    # (Xcode Command Line Tools); on Linux we add gcc below.
    cmake
    gnumake
    pkg-config

    # TeX + scientific publishing
    texliveFull
    quarto # .qmd/.ipynb -> PDF (via texliveFull) / HTML / reveal.js
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    gcc

    # Agent CLIs + archive tools. On macOS these come from Homebrew casks
    # (claude-code / codex) and the base system (unzip/zip). WSL has no Homebrew,
    # so pull them from Nix here — without claude-code, switching WSL to this
    # flake would drop the agent CLIs entirely (the thing the WSL box is *for*).
    claude-code
    codex
    unzip
    zip
  ];
}
