{ pkgs, lib, ... }:
# Development toolchains. Per-project versions belong in flake devShells;
# these are the global baselines.
let
  # quarto 1.9.37 emits the Pandoc 3.8 defaults key `syntax-highlighting`, but
  # nixpkgs pandoc is still 3.7.0 (only knows the old `highlight-style`), so
  # EVERY render dies with `Aeson exception: Unknown option "syntax-highlighting"`.
  # Rewrite the key back to the old name until nixpkgs bumps pandoc to 3.8.
  # `--replace-fail` aborts the build if the string is gone — that's the signal
  # the upstream fix landed and this whole override should be deleted (use plain
  # `quarto`). Tracking: https://github.com/NixOS/nixpkgs/issues/519484
  quarto = pkgs.quarto.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace bin/quarto.js \
        --replace-fail "syntax-highlighting" "highlight-style"
    '';
  });
in
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
    quarto # ← patched in the `let` above (nixpkgs#519484); .qmd/.ipynb -> PDF/HTML/revealjs
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
