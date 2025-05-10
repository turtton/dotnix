{ pkgs, ... }:
{
  home.packages = [
    pkgs.ghr
  ];
  programs.zsh = {
    initContent = ''
      source <(ghr shell bash)
      source <(ghr shell bash --completion)
    '';
  };
}
