{ pkgs, ... }: {
  home.packages = with pkgs; [
    bat # cat
    bottom # top
    du-dust # du
    eza # ls
    fd # find 
    ripgrep # grep
    delta # diff
  ];
  programs = {
    # cd
    zoxide.enable = true;
    # History Search(ctrl+r in zsh)
    atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
    };
    # Improve up-arrow search behavior
    zsh.initExtra = ''
      autoload -Uz history-beginning-search-backward
      zle -N history-beginning-search-backward
      bindkey '^[[A' history-beginning-search-backward
    '';
  };
}
