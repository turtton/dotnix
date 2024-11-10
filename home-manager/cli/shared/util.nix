{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Parsers
    jq
    jnv # jq interactive viewer
    yq-go

    # Archives
    unar
    unrar
    unzip
    zip

    wakatime # Development timer
    chezmoi # Dotfile management helper(1password cli integrated)
    fastfetch
    gnuplot_qt # graphing ulitity
  ];
}
