{ pkgs, ... }: {
  home.packages = with pkgs; [
    bat # cat
    bottom # top
    du-dust # du
    eza # ls
    fd # find 
    ripgrep # grep
    delta # diff
    zoxide # cd
  ];
  # History Search(ctrl+r in zsh)
  programs.atuin.enable = true;
}
