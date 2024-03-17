{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Parsers
    jq
    yq-go

    # Archives
    unar
    unrar
    unzip
    zip

    wakatime # Development timer
    chezmoi # Dotfile management helper(1password cli integrated)
    neofetch
  ];
}
