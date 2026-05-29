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
    ];
    casks = [
      "macskk"
      "omniwm"
      "codexbar"
      "background-music"
    ];
  };
}
