# nix-config — agent & contributor notes

Eric's Nix configuration. **One flake, three hosts:**

| Host | System | Hostname (flake attr) | Manager |
|------|--------|----------------------|---------|
| MacBook | `aarch64-darwin` | `Erics-MacBook-Pro` (matches `scutil --get LocalHostName`) | nix-darwin + home-manager |
| WSL | `x86_64-linux` | `wsl` (matches `networking.hostName`) | NixOS-WSL + home-manager |
| Server (`abs`) | `x86_64-linux` | `abs` (matches `networking.hostName`) | NixOS bare-metal + home-manager |

Username is `eric` on every host. Git identity: `You Wang` / `youwang.1997@gmail.com`.

**Guiding principle:** Homebrew **casks** for GUI / permission-requiring apps; **Nix + Home Manager** for CLI tools and dotfiles. Homebrew is declared *inside* nix-darwin (`homebrew.casks`), so everything stays in one declarative repo.

## Layout
- `flake.nix` — inputs + `darwinConfigurations.Erics-MacBook-Pro` + `nixosConfigurations.wsl` + `nixosConfigurations.abs` + shared home-manager wiring (`useGlobalPkgs`, `useUserPackages`, `backupFileExtension = "backup"`).
- `hosts/macbook/darwin.nix` → imports `modules/darwin/`.
- `hosts/wsl/configuration.nix` — NixOS-WSL system config.
- `hosts/server/{configuration,hardware-configuration}.nix` — bare-metal NixOS (`abs`): GNOME, NVIDIA (Blackwell, open modules), CUDA toolkit, VS Code + Zed, Syncthing, `sshd:10408` (key-only), Tailscale. `hardware-configuration.nix` is the **real** file generated on the box (btrfs subvolumes on one NVMe) — don't regenerate it casually.
- `modules/darwin/` — `system`, `nix`, `homebrew`, `mac-app-store`, `fonts`.
- `modules/home/` — `shell`, `git`, `ssh`, `cli`, `dev`, `yazi`, `direnv`, `ghostty` (shared by all hosts; ghostty writes the platform-correct config path — on macOS that's `~/Library/Application Support/com.mitchellh.ghostty/config`, filename exactly `config`).
- `modules/home/files/` — raw dotfiles copied verbatim (e.g. `sheldon/plugins.toml`).

## Decisions (don't re-litigate without a reason)
- **mise removed.** `uv` (Python), `nodejs`/`ruff`/`bun` (Nix), and the `codex`/`claude-code` Homebrew casks cover everything it did. Julia is via **juliaup**, installed *outside* Nix (Eric's own installer) — intentionally not in `dev.nix`.
- **No global `python313`** (uv manages interpreters). **No `llvmPackages.clang` on macOS** — use the system clang from Xcode Command Line Tools; Linux gets `gcc`.
- **LaTeX = `texliveFull` via Nix on every host** (not MacTeX).
- **Browser = Vivaldi** (only declared browser cask). `brave-browser` / `helium-browser` are left installed but unmanaged.
- **zsh on every host** (login shell on WSL + server too); **bash only on Linux** as a fallback.
- Cask naming: `claude` / `codex-app` are the **desktop apps**; `claude-code` / `codex` are the **CLIs**. `codex` is OpenAI's native Rust binary, **not** npm. **The casks are macOS-only** — WSL has no Homebrew, so on Linux `claude-code` + `codex` come from **Nix** in `modules/home/dev.nix` (Linux-gated branch). Don't drop them assuming brew covers WSL; it doesn't, and running these agents is what the WSL box is for.
- **`homebrew.onActivation.cleanup = "none"`** during migration (additive only). Flip to `"zap"` once the cask list is authoritative and unwanted apps (`brave-browser`, `helium-browser`, `mactex`, redundant CLI formulae) are removed.
- **Mac App Store apps are installed MANUALLY**, not via `homebrew.masApps` — nix-darwin#1722 (open) breaks the bundled `mas` and a failing mas step *aborts* `darwin-rebuild`. `modules/darwin/mac-app-store.nix` keeps them as a commented manifest (LocalSend, Telegram, WeChat, Tailscale, QSpace); re-enable when #1722 is fixed.
- **git** uses `programs.git.settings.user.{name,email}` — the current freeform schema. `userName`/`userEmail` are deprecated aliases.
- **ssh** uses `enableDefaultConfig = false` + `settings."*" = {}` + `extraConfig` — the modern schema; the empty `settings."*"` satisfies the assertion that fires when `extraConfig` is used. Host `abs` resolves via Tailscale MagicDNS.
- **Server `abs` (NixOS, i7-14700 + RTX 5060 Blackwell):** GNOME desktop. NVIDIA **open** kernel modules (`hardware.nvidia.open = true`) are *required* for Blackwell — proprietary modules don't support RTX 50-series; driver must be ≥ 575 (`nvidiaPackages.production`, verify the version at install). **CUDA = `cudaPackages.cudatoolkit` only** — deliberately *no* global `nixpkgs.config.cudaSupport` (it mass-rebuilds the closure). `sshd` on **port 10408** (matches the Mac's `Host abs` client block) exposed on LAN + Tailscale, **key-only** — the Mac's `id_ed25519_abs.pub` is baked into `authorizedKeys`; console password login still works at the machine. Kernel = `linuxPackages_latest` (what the installer set up) — if `nvidia-open` ever fails to build against a too-new kernel, drop `boot.kernelPackages` to fall back to the LTS default. GUI apps come from **Nix** on Linux (no Homebrew): `vscode-fhs` (FHS env so marketplace extensions with native binaries work), `zed-editor`, firefox; `neovim` stays as the terminal editor on the box. GDM auto-suspend + all systemd sleep targets are **disabled** (box must stay SSH-reachable). `nix-ld` is on so VS Code Remote-SSH / Zed remote servers run unpatched. **Syncthing** runs as `eric` (GUI on `localhost:8384` — reached from the Mac via the `Host abs` LocalForward, browse `localhost:9394`). Weekly nix GC + fstrim, monthly btrfs scrub. First install = NixOS **26.05** (`system.stateVersion`, don't bump). `hardware-configuration.nix` is the real generated file: btrfs root + `home`/`nix` subvolumes on one NVMe + swap partition.

## Shell completion — do NOT "fix" this again
`programs.zsh.enableCompletion = false` in `modules/home/shell.nix` is **intentional**: it lets us run `compinit` ourselves *before* sheldon sources `fzf-tab` (fzf-tab must load after compinit).

**Do not add a manual `fpath=(...)` line for tool completions.** nix-darwin's `/etc/zshrc` already prepends every profile completion dir (`/etc/profiles/per-user/eric/share/zsh/site-functions`, `/run/current-system/sw/...`, …) to `fpath` *before* `~/.zshrc` runs. Verified empirically: `gh`'s `_gh` registers with no manual fpath line. We already burned a long session rediscovering this.

## Gotchas
- **Nix is installed and the config is deployed.** `command -v nix` returns nothing in a *non-login* shell (e.g. an agent's default Bash tool) — that's a PATH artifact, **not** a missing install. For nix/zsh-aware checks use a login+interactive shell: `zsh -lic '...'`.
- **Flakes only see git-tracked files** → run `git add -A` before any rebuild, or new modules are invisible to the build.
- Homebrew must be installed manually once; nix-darwin only *manages* packages, it does not install brew.
- `system.primaryUser = "eric"` is required by current nix-darwin.
- If Nix was installed with the **Determinate** installer, set `nix.enable = false` in `modules/darwin/nix.nix` (commented toggle) or `darwin-rebuild` aborts with "Determinate detected".

## Fresh-machine bootstrap (macOS)
On a brand-new Mac `darwin-rebuild` does not exist yet — you bootstrap it once with `nix run`. Order matters.

```bash
# 1. Xcode Command Line Tools (git, compilers, Homebrew prerequisite)
xcode-select --install

# 2. Install Nix — pick ONE:
#    a) Determinate installer  → then keep `nix.enable = false` in modules/darwin/nix.nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
#    b) Official upstream installer (flakes get enabled inline in step 5)
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
# open a NEW terminal afterwards so `nix` is on PATH

# 3. Install Homebrew (nix-darwin MANAGES casks but does NOT install brew itself)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 4. Get this repo and track files (flakes ignore untracked files)
git clone <repo-url> ~/Desktop/nix-config && cd ~/Desktop/nix-config
git add -A

# 5. First nix-darwin activation — this builds `darwin-rebuild` itself.
#    --extra-experimental-features is only needed this first time (upstream installer).
sudo nix run github:nix-darwin/nix-darwin/master#darwin-rebuild \
  --extra-experimental-features "nix-command flakes" \
  -- switch --flake .#Erics-MacBook-Pro

# 6. From now on the normal command works (see below).
# 7. Install the Mac App Store apps by hand (mac-app-store.nix is disabled, #1722):
#    LocalSend, Telegram, WeChat, Tailscale, QSpace
```
If the machine's hostname differs from `Erics-MacBook-Pro`, either keep passing `--flake .#Erics-MacBook-Pro` explicitly, set it with `sudo scutil --set LocalHostName Erics-MacBook-Pro`, or edit `macHostname` in `flake.nix`.

> WSL is bootstrapped separately: install the NixOS-WSL distro first, then `sudo nixos-rebuild switch --flake .#wsl`.

## Fresh-machine bootstrap (NixOS server `abs`)
**Status: DONE (June 2026).** The box was installed from the vanilla 26.05 ISO; the repo now carries its real `hardware-configuration.nix` and the Mac's pubkey is in `authorizedKeys`. What's left is adopting the flake on the running box:

```bash
# on abs — git is not in the vanilla install, and flakes aren't enabled yet:
nix-shell -p git --run 'git clone <repo-url> ~/nix-config'    # or rsync the repo over
cd ~/nix-config
sudo nixos-rebuild switch --flake .#abs \
  --option extra-experimental-features 'nix-command flakes'   # flag needed only this first time
# afterwards: hostname becomes `abs`, sshd moves 22 → 10408 (key-only)
sudo tailscale up
nvidia-smi                                    # RTX 5060 listed, driver >= 575
```

The ISO runbook below is kept for a future re-install only.

```bash
# 1. Boot the NixOS installer ISO. Partition (UEFI: ESP + root), format, and
#    mount root at /mnt (ESP at /mnt/boot).

# 2. Generate hardware config FROM the real machine:
sudo nixos-generate-config --root /mnt      # writes /mnt/etc/nixos/hardware-configuration.nix

# 3. Get this repo onto the box, then overwrite the placeholder with the generated file:
#    cp /mnt/etc/nixos/hardware-configuration.nix <repo>/hosts/server/hardware-configuration.nix

# 4. Paste your SSH pubkey into hosts/server/configuration.nix (authorizedKeys).
#    From the Mac:  cat ~/.ssh/id_ed25519_abs.pub
git add -A                                   # flakes ignore untracked files

# 5. Install (sets up the bootloader, builds the system):
sudo nixos-install --flake <repo>#abs        # set the eric password when prompted, then reboot

# 6. After reboot: join Tailscale and confirm the GPU:
sudo tailscale up
nvidia-smi                                   # should list the RTX 5060
nix eval .#nixosConfigurations.abs.config.hardware.nvidia.package.version   # expect >= 575

# 7. From the Mac (already has the `Host abs` client block):  ssh abs
```

## Commands
```bash
# --- macOS rebuild (run from repo root) ---
git add -A                                            # flakes ignore untracked files
darwin-rebuild switch --flake .#Erics-MacBook-Pro     # prefix with sudo if prompted

# --- WSL / NixOS rebuild ---
sudo nixos-rebuild switch --flake .#wsl

# --- server (abs) rebuild (run on the box) ---
sudo nixos-rebuild switch --flake .#abs

# --- evaluate / dry-run without switching ---
nix flake check
darwin-rebuild build --flake .#Erics-MacBook-Pro      # builds, doesn't activate

# --- update inputs ---
nix flake update                                      # all inputs
nix flake update nixpkgs                               # just one

# --- generations / rollback (macOS) ---
darwin-rebuild --list-generations
darwin-rebuild switch --rollback

# --- disk cleanup ---
nix-collect-garbage -d

# --- verify shell completion + fzf-tab in a REAL shell ---
zsh -lic 'echo "gh -> ${_comps[gh]:-NONE}"; bindkey | grep -i "\^I"'
# expect:  gh -> _gh   and   "^I" fzf-tab-complete
```
