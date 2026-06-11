{ pkgs, lib, ... }:
# SSH client config for the Mac. WSL does not need this user SSH profile.
{
  programs.ssh = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = { };

    extraConfig = ''
      Host abs
          HostName abs
          User eric
          Port 10408
          IdentityFile ~/.ssh/id_ed25519_abs
          IdentitiesOnly yes
          UseKeychain yes
          AddKeysToAgent yes
          LocalForward 9394 localhost:8384
    '';
  };
}
