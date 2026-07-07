{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "mtgto/macskk"
      "BarutSRB/tap"
      "steipete/tap"
      "fuwasegu/tap"
    ];
    casks = [
      "macskk"
      "omniwm"
      "codexbar"
      "background-music"
      "scroll-reverser"
      "airlingua"
      "deskpad"
    ];
  };
}
