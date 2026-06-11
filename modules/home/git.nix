{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "You Wang";
        email = "youwang.1997@gmail.com";
      };
      # git push/pull to GitHub authenticates through `gh auth login`'s token.
      # gh ships via cli.nix on every host, so this works on mac/wsl/abs alike.
      credential."https://github.com".helper = "!gh auth git-credential";
    };
  };
}
