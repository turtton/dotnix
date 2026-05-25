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
    ];
    casks = [
      "macskk"
      "omniwm"
    ];
  };
}
