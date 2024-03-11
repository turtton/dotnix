{pkgs, ...}: {
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

    neofetch
  ];
}