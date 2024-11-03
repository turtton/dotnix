{ pkgs, ... }:
{
  home.packages = [
    pkgs.ghr
  ];
  programs.zsh = {
    initExtra = ''
      source <(ghr shell bash)
      source <(ghr shell bash --completion)
    '';
  };
}
