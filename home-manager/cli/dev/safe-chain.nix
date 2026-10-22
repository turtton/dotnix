{ pkgs, ... }:
{
  home.packages = [ pkgs.safe-chain ];

  programs.zsh.initContent = ''
    source ${pkgs.safe-chain}/scripts/init-posix.sh
  '';
}
