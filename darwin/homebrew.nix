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
    # https://github.com/nix-darwin/nix-darwin/issues/1787
    onActivation.extraFlags = [
      "--force-cleanup"
    ];
  };
}
