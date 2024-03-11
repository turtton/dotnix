{pkgs, ...}: {
  home.packages = with pkgs; [
    bat # cat
    bottom # top
    du-dust # du
    eza # ls
    fd # find 
    ripgrep # grep
  ];
}