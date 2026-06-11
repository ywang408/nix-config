{ ... }:
# Mac App Store apps — currently installed MANUALLY from the App Store, NOT
# declaratively. nix-darwin's masApps is broken by an upstream mas/brew change
# (open issue nix-darwin#1722; the bundled mas is 2.2.2). A failing mas step
# aborts the whole `darwin-rebuild switch`, so we keep it out of activation.
#
# Re-enable by uncommenting once #1722 is resolved. App IDs come from `mas list`.
{
  # homebrew.masApps = {
  #   LocalSend = 1661733229;
  #   Telegram  = 747648890;
  #   WeChat    = 836500024;
  #   Tailscale = 1475387142;
  #   QSpace    = 1469774098;
  # };
}
