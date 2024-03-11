{
  imports = [./starship.nix];
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
  };
}