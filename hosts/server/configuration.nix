{ config, lib, pkgs, username, ... }:
# NixOS server `abs` — Intel i7-14700 + NVIDIA RTX 5060 (Blackwell).
# GNOME desktop, CUDA toolkit, VS Code + Zed, sshd on a non-standard port,
# Tailscale, Syncthing. Disk layout (btrfs subvolumes, ESP, swap) lives in
# ./hardware-configuration.nix, generated on the machine by `nixos-generate-config`.
{
  imports = [ ./hardware-configuration.nix ];

  # ---------- Boot ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Latest kernel — what the installer set up and what the box has run since day
  # one. If nvidia-open ever fails to build against a too-new kernel, delete
  # this line to fall back to the default (LTS) kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "abs";
  networking.networkmanager.enable = true; # GNOME integrates with NetworkManager

  # ---------- Nix ----------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true; # nvidia, cuda, vscode, claude-code, codex
  # texliveFull + CUDA + GNOME closures add up fast; keep old generations bounded.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true; # dedupe the store via hardlinks

  # ---------- i18n / time ----------
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # ---------- User ----------
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    # The Mac's dedicated key for this box (~/.ssh/id_ed25519_abs.pub there);
    # pairs with the `Host abs` client block in modules/home/ssh.nix.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKASbrTBf6WfN8+oyB0gF9DwoDimgNoIStnOrrfVPL7E eric@macbook-abs"
    ];
  };
  # zsh enabled system-wide so it's a valid login shell (user config: modules/home/shell.nix).
  programs.zsh.enable = true;

  # ---------- Intel 14700 ----------
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # ---------- NVIDIA RTX 5060 (Blackwell) ----------
  # Blackwell REQUIRES the open kernel modules; the proprietary modules do not
  # support RTX 50-series. Needs driver >= 575 — `production` should satisfy this
  # on current nixpkgs; verify with:
  #   nix eval .#nixosConfigurations.abs.config.hardware.nvidia.package.version
  # and fall back to `nvidiaPackages.beta` / `.latest` if it's older than 575.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true; # Blackwell: required
    modesetting.enable = true; # required for Wayland / GNOME
    nvidiaSettings = true; # nvidia-settings GUI (desktop)
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # ---------- GNOME desktop ----------
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb.layout = "us";

  # This box must stay reachable over SSH: GDM's idle auto-suspend (ON by
  # default!) and every systemd sleep target are disabled.
  services.displayManager.gdm.autoSuspend = false;
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # ---------- Audio / printing ----------
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.printing.enable = true; # CUPS

  # ---------- Fonts ----------
  # Mirrors modules/darwin/fonts.nix so terminals + editors render identically.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # ---------- Packages ----------
  # CLI tools + dotfiles come from home-manager (modules/home/), shared with the
  # Mac — including the claude-code + codex CLIs (Linux branch of dev.nix).
  # CUDA: native toolkit only (nvcc, libraries). We deliberately do NOT set
  # `nixpkgs.config.cudaSupport = true` — that rebuilds much of the closure
  # against CUDA. Install per-project CUDA deps in flake devShells as needed.
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit

    # GUI editors. vscode-fhs runs VS Code inside an FHS env so marketplace
    # extensions that ship prebuilt native binaries work unpatched (plain
    # `vscode` chokes on some of them under NixOS).
    vscode-fhs
    zed-editor

    # Terminal editor on the box (was hand-installed pre-flake; keep it).
    neovim
  ];
  programs.firefox.enable = true;

  # Run foreign dynamically-linked binaries unpatched: the VS Code Remote-SSH /
  # Zed remote servers (when connecting from the Mac), mason.nvim, uv wheels…
  programs.nix-ld.enable = true;

  # ---------- SSH (key-only) ----------
  # Port 10408 matches the Mac's `Host abs` client block in modules/home/ssh.nix.
  # The Mac's pubkey is in authorizedKeys above; console password login at the
  # machine still works if the key is ever lost.
  services.openssh = {
    enable = true;
    ports = [ 10408 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ---------- Tailscale ----------
  services.tailscale.enable = true;

  # ---------- Syncthing ----------
  # The Mac's `Host abs` block forwards localhost:9394 → abs:8384 — that is this
  # GUI (Syncthing binds it to 127.0.0.1 only). Folders/devices: configure in the UI.
  services.syncthing = {
    enable = true;
    user = username;
    group = "users";
    dataDir = "/home/${username}";
    openDefaultPorts = true; # 22000 tcp/udp sync + 21027/udp discovery (LAN sync)
  };

  # ---------- Firewall ----------
  # LAN + Tailscale: ssh reachable on all interfaces; tailscale0 fully trusted.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 10408 ];
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose"; # recommended with Tailscale
  };

  # ---------- Disk maintenance ----------
  services.fstrim.enable = true; # weekly TRIM (NVMe)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ]; # one device; scrubbing / covers the home/nix subvols
  };

  # Release this box was first installed with (June 2026, vanilla ISO) — do not bump.
  system.stateVersion = "26.05";
}
