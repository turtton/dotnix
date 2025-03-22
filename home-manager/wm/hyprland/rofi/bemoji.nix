{ pkgs, ... }: {
  home.packages = with pkgs; [
    bemoji # emoji picker
  ];
  # https://github.com/marty-oehme/bemoji?tab=readme-ov-file#adding-your-own-emoji
  xdg.dataFile."bemoji/shortcodes.txt".source = ./bemoji.txt;
}
